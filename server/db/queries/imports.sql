-- name: CreateImport :one
INSERT INTO imports (user_id, source, address, secret, folder) VALUES ($1, $2, $3, $4, $5) RETURNING id;

-- name: GetImport :one
SELECT * FROM imports WHERE id = $1;

-- name: ListImports :many
SELECT i.*, u.email AS user_email FROM imports i JOIN users u ON u.id = i.user_id ORDER BY i.created_at DESC LIMIT 50;

-- name: AddImportCounts :exec
UPDATE imports SET added = added + sqlc.arg('added'), skipped = skipped + sqlc.arg('skipped'), failed = failed + sqlc.arg('failed'),
    last_error = CASE WHEN sqlc.arg('last_error')::text = '' THEN last_error ELSE sqlc.arg('last_error')::text END
WHERE id = sqlc.arg('id');

-- name: SetImportPage :exec
UPDATE imports SET page = $2 WHERE id = $1;

-- name: FinishImport :exec
UPDATE imports SET status = $2, last_error = CASE WHEN $3::text = '' THEN last_error ELSE $3::text END, secret = '', finished_at = now()
WHERE id = $1 AND status = 'running';

-- name: GetImportMap :one
SELECT local_id FROM import_map WHERE user_id = $1 AND origin = $2 AND kind = $3 AND remote_id = $4;

-- name: SetImportMap :exec
INSERT INTO import_map (user_id, origin, kind, remote_id, local_id) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (user_id, origin, kind, remote_id) DO UPDATE SET local_id = EXCLUDED.local_id;

-- name: AddFaceHint :exec
INSERT INTO face_hints (asset_id, person_id, x1, y1, x2, y2) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT DO NOTHING;

-- name: ListFaceHints :many
SELECT person_id, x1, y1, x2, y2 FROM face_hints WHERE asset_id = $1;

-- name: SetImportFacts :exec
UPDATE assets SET import_taken_at = $2, import_latitude = $3, import_longitude = $4 WHERE id = $1;

-- name: MarkImportedFavorite :exec
UPDATE assets SET is_favorite = true WHERE id = $1;

-- name: MarkImportedArchived :exec
UPDATE assets SET archived_at = now() WHERE id = $1 AND archived_at IS NULL;

-- name: CreateNamedPerson :one
INSERT INTO people (user_id, name, hidden) VALUES ($1, $2, $3) RETURNING id;

-- name: MovePersonImports :exec
UPDATE import_map SET local_id = sqlc.arg('target')
WHERE user_id = sqlc.arg('user_id') AND kind = 'person' AND local_id = ANY(sqlc.arg('sources')::uuid[]);

-- name: MovePersonHints :exec
INSERT INTO face_hints (asset_id, person_id, x1, y1, x2, y2)
SELECT asset_id, sqlc.arg('target'), x1, y1, x2, y2 FROM face_hints
WHERE person_id = ANY(sqlc.arg('sources')::uuid[])
ON CONFLICT DO NOTHING;

-- name: ListAssetsWithoutSHA1 :many
SELECT id, original_path FROM assets
WHERE user_id = $1 AND checksum_sha1 IS NULL AND id > $2
ORDER BY id LIMIT $3;

-- name: SetAssetSHA1 :exec
UPDATE assets SET checksum_sha1 = $2 WHERE id = $1;

-- name: GetAssetIDBySHA1 :one
SELECT id FROM assets WHERE user_id = $1 AND checksum_sha1 = $2 LIMIT 1;

-- name: DeleteFaceHint :exec
DELETE FROM face_hints WHERE asset_id = $1 AND person_id = $2 AND x1 = $3 AND y1 = $4;

-- name: AddFaceIgnored :exec
INSERT INTO face_ignored (asset_id, x1, y1, x2, y2) VALUES ($1, $2, $3, $4, $5) ON CONFLICT DO NOTHING;

-- name: ListFaceIgnored :many
SELECT x1, y1, x2, y2 FROM face_ignored WHERE asset_id = $1;
