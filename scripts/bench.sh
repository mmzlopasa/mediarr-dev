#!/bin/bash
# Measures the app on a temporary production install with 100k rows, which it then deletes, and
# exits non-zero when a limit in web/bench/limits.mjs is exceeded.
# Nothing touches the demo. Thumbnails share one real file, so this measures the app, not the disk.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PORT=${BENCH_PORT:-9857}
WORK=$(mktemp -d "$ROOT/.dev/bench-XXXXXX")
PASSWORD=$(openssl rand -hex 16)
mkdir -p "$WORK/library" "$WORK/cache" "$WORK/db" "$WORK/results"
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

# Search needs the real model, because reading the query is part of what is measured.
MODELS=${DEV_MODELS:-$WORK/models}
mkdir -p "$MODELS"
cat >"$WORK/override.yaml" <<YAML
services:
  server:
    environment:
      ML_URL: http://ml:8000
  db:
    # Building the search index on 100k vectors in parallel takes shared memory.
    shm_size: 3gb
  ml:
    environment:
      ML_THREADS: "4"
      MODEL_DIR: /models
    user: "$(id -u):$(id -g)"
    volumes:
      - $MODELS:/models
YAML

# Compose reads docker/.env for the containers, so it has to exist on a fresh checkout too.
[ -e "$ROOT/docker/.env" ] || cp "$ROOT/docker/example.env" "$ROOT/docker/.env"
COMPOSE=(docker compose -p mediarr-bench --profile ml --env-file "$WORK/env" -f "$ROOT/docker/docker-compose.yml" -f "$ROOT/docker/docker-compose.prod.yml" -f "$WORK/override.yaml")

cleanup() {
	"${COMPOSE[@]}" down -v >/dev/null 2>&1 || true
	docker run --rm -v "$WORK:/w" alpine:3 sh -c 'rm -rf /w/*' >/dev/null 2>&1 || true
	rm -rf "$WORK"
}
trap cleanup EXIT

"${COMPOSE[@]}" up -d --build --wait server db nginx ml 2>&1 | tail -1

printf '%s\n' "$PASSWORD" | "${COMPOSE[@]}" exec -T server /mediarr user upsert bench@example.com "Bench" 
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$WORK/cache:/c" mediarr-dev-go \
	sh -c 'vips gaussnoise /c/source.jpg 250 180 --seed 1 && vips thumbnail /c/source.jpg "/c/bench.webp[Q=82,strip]" 250'

"${COMPOSE[@]}" exec -T db psql -q -U mediarr -d mediarr <<'SQL'
INSERT INTO libraries (user_id, name, kind) SELECT id, 'Uploads', 'upload' FROM users WHERE email = 'bench@example.com';
-- What a real library holds, so that Clean up has something to count: videos, screenshots,
-- photos of every sharpness, EXIF on each, and bursts.
INSERT INTO assets (user_id, library_id, checksum, original_name, original_path, size_bytes, mime_type, kind, status,
                    width, height, aspect_ratio, blurhash, taken_at, taken_offset_minutes, duration_ms, sharpness)
SELECT u.id, l.id, sha256(('bench-' || n)::text::bytea),
       CASE WHEN t.video THEN 'VID_' || n || '.mp4' WHEN t.shot THEN 'Screenshot_' || n || '.png' ELSE 'IMG_' || n || '.jpg' END,
       '/data/library/none/' || n,
       CASE WHEN t.video THEN (50 + n % 7 * 300) * 1000000 ELSE 3000000 END,
       CASE WHEN t.video THEN 'video/mp4' WHEN t.shot THEN 'image/png' ELSE 'image/jpeg' END,
       CASE WHEN t.video THEN 'video' ELSE 'photo' END, 'ready',
       CASE WHEN t.shot THEN 1170 ELSE 4032 END, CASE WHEN t.shot THEN 2532 ELSE 3024 END,
       CASE WHEN t.shot THEN 0.46 ELSE (ARRAY[1.33, 0.75, 1.78, 1.0, 1.5])[1 + n % 5] END, 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
       timestamptz '2026-01-01' - (n * interval '40 minutes'), 60,
       CASE WHEN t.video THEN 60000 END,
       CASE WHEN NOT t.video AND n % 100 <> 1 THEN (n * 7919 % 400)::real END
FROM users u JOIN libraries l ON l.user_id = u.id, generate_series(1, 100000) AS n,
     LATERAL (SELECT n % 20 = 0 AS video, n % 33 = 0 AND n % 20 <> 0 AS shot) t
WHERE u.email = 'bench@example.com';
-- Bursts come on top of the 100k, as the timeline shows only the main shot of each.
-- Every fifth is a RAW beside its JPEG, which is a pair and not a burst.
INSERT INTO assets (user_id, library_id, checksum, original_name, original_path, size_bytes, mime_type, kind, status,
                    width, height, aspect_ratio, blurhash, taken_at, taken_offset_minutes, sharpness, stack_parent)
SELECT p.user_id, p.library_id, sha256(('burst-' || k)::text::bytea),
       CASE WHEN k % 5 = 0 THEN regexp_replace(p.original_name, '\.[^.]*$', '.dng') ELSE 'IMG_B' || k || '.jpg' END,
       '/data/library/none/b' || k, 3000000, 'image/jpeg', 'photo', 'ready', 4032, 3024, 1.33, p.blurhash,
       p.taken_at + interval '1 second', 60, (k * 7919 % 400)::real, p.id
FROM generate_series(1, 2000) AS k JOIN assets p ON p.checksum = sha256(('bench-' || (50 * k - 49))::text::bytea);
INSERT INTO asset_files (asset_id, kind, path, size_bytes)
SELECT a.id, k.kind, '/data/cache/bench.webp', 1000 FROM assets a, (VALUES ('thumb_small'), ('thumb_large')) AS k(kind);
-- Screenshots have no camera; some camera rows carry the mark an iPhone leaves.
INSERT INTO exif (asset_id, make, model, iso, f_number, focal_length, raw)
SELECT a.id, CASE WHEN NOT a.screenshot_hint THEN 'Apple' END, CASE WHEN NOT a.screenshot_hint THEN 'iPhone 15 Pro' END,
       100 + a.rn % 800, 1.8, 24,
       jsonb_build_object('Make', 'Apple', 'Model', 'iPhone 15 Pro', 'ISO', 100 + a.rn % 800, 'LensModel', 'iPhone 15 Pro back camera')
       || CASE WHEN a.rn % 200 = 0 THEN '{"UserComment": "Screenshot"}'::jsonb ELSE '{}'::jsonb END
FROM (SELECT id, screenshot_hint, row_number() OVER () AS rn FROM assets) a;
ANALYZE;
SQL

# Random vectors spread evenly, which is harder for the index than real photos are.
"${COMPOSE[@]}" exec -T db psql -q -v ON_ERROR_STOP=1 -U mediarr -d mediarr <<'SQL'
DROP INDEX asset_search_embedding_idx;
INSERT INTO asset_search (asset_id, embedding)
SELECT a.id, (SELECT array_agg(random() - 0.5) FROM generate_series(1, 768) WHERE a.n > 0)::real[]::vector
FROM (SELECT id, row_number() OVER () AS n FROM assets) a;
SET maintenance_work_mem = '2GB';
SET max_parallel_maintenance_workers = 4;
CREATE INDEX asset_search_embedding_idx ON asset_search USING hnsw (embedding vector_cosine_ops);
ANALYZE asset_search;
SQL

VERSION=$(cd "$ROOT/web" && node -p "require('./node_modules/@playwright/test/package.json').version")
docker run --rm --network host --user "$(id -u):$(id -g)" -e HOME=/tmp \
	-e BENCH_URL="http://127.0.0.1:$PORT" -e BENCH_PASSWORD="$PASSWORD" -e BENCH_SKIP_FPS="${BENCH_SKIP_FPS:-}" \
	-e BENCH_RESULTS=/results/results.jsonl -v "$WORK/results:/results" \
	-v "$ROOT/web:/web" -w /web "mcr.microsoft.com/playwright:v$VERSION-noble" \
	node_modules/.bin/playwright test --config=playwright.bench.config.ts --reporter=line || TESTS=$?

# The server after it has served all of the above, left alone for a minute. docker stats leaves out
# the page cache. Only the server container counts: ML is its own service, and the worker is not run
# here, as it would only find files that do not exist.
sleep 60
SERVER=$("${COMPOSE[@]}" ps -q server)
SAMPLES=$(for _ in 1 2 3 4 5; do
	docker stats --no-stream --format '{{.MemUsage}}' "$SERVER" | awk '{
		unit = $1; sub(/^[0-9.]+/, "", unit)
		print $1 * (unit == "GiB" ? 1073741824 : unit == "MiB" ? 1048576 : unit == "KiB" ? 1024 : 1) / 1000000
	}'
	sleep 2
done | sort -n | tr '\n' ' ')
read -r -a MEMORY <<<"$SAMPLES"
if [ "${#MEMORY[@]}" -eq 5 ]; then
	printf '{"key":"idleRam","value":%.0f,"detail":"median of 5 samples, after the load and 60 s of rest"}\n' \
		"${MEMORY[2]}" >>"$WORK/results/results.jsonl"
fi

node "$ROOT/web/bench/report.mjs" "$WORK/results/results.jsonl" || REPORT=$?
exit $((${TESTS:-0} | ${REPORT:-0}))
