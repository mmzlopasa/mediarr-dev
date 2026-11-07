-- name: GetExternalLibrary :one
SELECT * FROM libraries WHERE kind = 'external' LIMIT 1;

-- name: CreateExternalLibrary :one
INSERT INTO libraries (user_id, name, kind, path) VALUES ($1, 'External', 'external', $2) RETURNING *;

-- name: DeleteExternalLibrary :exec
DELETE FROM libraries WHERE kind = 'external';

-- name: ExternalLibraryCounts :one
SELECT count(*) AS assets, count(*) FILTER (WHERE missing_at IS NOT NULL) AS missing
FROM assets WHERE library_id = $1;

-- name: StartExternalScan :exec
UPDATE libraries SET scan_started_at = now(), scan_finished_at = NULL, scan_error = NULL WHERE id = $1;

-- name: FinishExternalScan :exec
UPDATE libraries SET scan_finished_at = now(), scan_error = $2 WHERE id = $1;

-- name: ListExternalFiles :many
SELECT path, size_bytes, mtime FROM external_files WHERE library_id = $1;

-- name: UpsertExternalFile :exec
INSERT INTO external_files (library_id, path, size_bytes, mtime) VALUES ($1, $2, $3, $4)
ON CONFLICT (library_id, path) DO UPDATE SET size_bytes = EXCLUDED.size_bytes, mtime = EXCLUDED.mtime;

-- name: FindAssetByChecksum :one
SELECT id, library_id, original_path FROM assets WHERE user_id = $1 AND checksum = $2;

-- name: FindExternalAssetByPath :one
SELECT id FROM assets WHERE library_id = $1 AND original_path = $2;

-- name: InsertExternalAsset :one
INSERT INTO assets (user_id, library_id, checksum, original_name, original_path, size_bytes, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (user_id, checksum) DO NOTHING
RETURNING id;

-- name: MoveExternalAsset :exec
UPDATE assets SET original_path = $2, original_name = $3, missing_at = NULL, updated_at = now() WHERE id = $1;

-- name: ReplaceExternalContent :exec
UPDATE assets
SET checksum = $2, size_bytes = $3, missing_at = NULL, status = 'processing', phash = NULL, sharpness = NULL,
    organized_at = NULL, updated_at = now()
WHERE id = $1;

-- name: ListExternalAssetPaths :many
SELECT id, original_path, missing_at FROM assets WHERE library_id = $1;

-- name: SetAssetsMissing :exec
UPDATE assets SET missing_at = now() WHERE id = ANY($1::uuid[]) AND missing_at IS NULL;

-- name: ClearAssetsMissing :exec
UPDATE assets SET missing_at = NULL WHERE id = ANY($1::uuid[]);

-- name: ListFolderChildren :many
SELECT split_part(substr(a.original_path, length(sqlc.arg('prefix')::text) + 1), '/', 1)::text AS name,
       count(*) AS count,
       (array_agg(a.id ORDER BY a.local_at DESC, a.id))[1]::uuid AS cover_id
FROM assets a
WHERE a.library_id = sqlc.arg('library_id') AND a.user_id = sqlc.arg('user_id')
  AND starts_with(a.original_path, sqlc.arg('prefix')::text)
  AND position('/' IN substr(a.original_path, length(sqlc.arg('prefix')::text) + 1)) > 0
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL
  AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
GROUP BY 1
ORDER BY 1;

-- name: ListFolderItems :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live,
       0::bigint AS stack_members,
       (a.projection IS NOT NULL)::boolean AS is_panorama
FROM assets a
WHERE a.library_id = sqlc.arg('library_id') AND a.user_id = sqlc.arg('user_id')
  AND starts_with(a.original_path, sqlc.arg('prefix')::text)
  AND position('/' IN substr(a.original_path, length(sqlc.arg('prefix')::text) + 1)) = 0
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL
  AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
ORDER BY a.local_at DESC, a.id DESC
LIMIT sqlc.arg('row_limit');
