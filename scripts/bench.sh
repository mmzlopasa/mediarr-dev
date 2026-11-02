#!/bin/bash
# Measures the timeline on a temporary production install with 100k rows, which it then deletes.
# Nothing touches the demo. Thumbnails share one real file, so this measures the app, not the disk.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PORT=${BENCH_PORT:-9856}
WORK=$(mktemp -d "$ROOT/.dev/bench-XXXXXX")
PASSWORD=$(openssl rand -hex 16)
mkdir -p "$WORK/library" "$WORK/cache" "$WORK/db"
cat >"$WORK/env" <<ENV
DB_USER=mediarr
DB_PASSWORD=$(openssl rand -hex 12)
UPLOAD_LOCATION=$WORK/library
CACHE_LOCATION=$WORK/cache
DB_LOCATION=$WORK/db
PUID=$(id -u)
PGID=$(id -g)
BIND_ADDRESS=127.0.0.1
HTTP_PORT=$PORT
ENV

# Compose reads deploy/.env for the containers, so it has to exist on a fresh checkout too.
[ -e "$ROOT/deploy/.env" ] || cp "$ROOT/deploy/.env.example" "$ROOT/deploy/.env"
COMPOSE=(docker compose -p mediarr-bench --env-file "$WORK/env" -f "$ROOT/deploy/compose.yaml" -f "$ROOT/deploy/compose.build.yaml")

cleanup() {
	"${COMPOSE[@]}" down -v >/dev/null 2>&1 || true
	docker run --rm -v "$WORK:/w" alpine:3 sh -c 'rm -rf /w/*' >/dev/null 2>&1 || true
	rm -rf "$WORK"
}
trap cleanup EXIT

"${COMPOSE[@]}" up -d --build --wait server db nginx 2>&1 | tail -1

printf '%s\n' "$PASSWORD" | "${COMPOSE[@]}" exec -T server /mediarr user upsert bench@example.com "Bench" 
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$WORK/cache:/c" mediarr-dev-go \
	sh -c 'vips gaussnoise /c/source.jpg 250 180 --seed 1 && vips thumbnail /c/source.jpg "/c/bench.webp[Q=82,strip]" 250'

"${COMPOSE[@]}" exec -T db psql -q -U mediarr -d mediarr <<'SQL'
INSERT INTO libraries (user_id, name, kind) SELECT id, 'Uploads', 'upload' FROM users WHERE email = 'bench@example.com';
INSERT INTO assets (user_id, library_id, checksum, original_name, original_path, size_bytes, mime_type, kind, status,
                    width, height, aspect_ratio, blurhash, taken_at, taken_offset_minutes)
SELECT u.id, l.id, sha256(('bench-' || n)::text::bytea), 'IMG_' || n || '.jpg', '/data/library/none/' || n, 3000000, 'image/jpeg',
       'photo', 'ready', 4032, 3024, (ARRAY[1.33, 0.75, 1.78, 1.0, 1.5])[1 + n % 5], 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
       timestamptz '2026-01-01' - (n * interval '40 minutes'), 60
FROM users u JOIN libraries l ON l.user_id = u.id, generate_series(1, 100000) AS n
WHERE u.email = 'bench@example.com';
INSERT INTO asset_files (asset_id, kind, path, size_bytes)
SELECT a.id, k.kind, '/data/cache/bench.webp', 1000 FROM assets a, (VALUES ('thumb_small'), ('thumb_large')) AS k(kind);
ANALYZE;
SQL

VERSION=$(cd "$ROOT/web" && node -p "require('./node_modules/@playwright/test/package.json').version")
docker run --rm --network host --user "$(id -u):$(id -g)" -e HOME=/tmp \
	-e BENCH_URL="http://127.0.0.1:$PORT" -e BENCH_PASSWORD="$PASSWORD" -e BENCH_SKIP_FPS="${BENCH_SKIP_FPS:-}" \
	-v "$ROOT/web:/web" -w /web "mcr.microsoft.com/playwright:v$VERSION-noble" \
	node_modules/.bin/playwright test --config=playwright.bench.config.ts --reporter=line
