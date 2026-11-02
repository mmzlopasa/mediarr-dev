-- name: CreateUploadLibrary :exec
INSERT INTO libraries (user_id, name, kind) VALUES ($1, 'Uploads', 'upload')
ON CONFLICT (user_id) WHERE kind = 'upload' DO NOTHING;

-- name: GetUploadLibrary :one
SELECT id FROM libraries WHERE user_id = $1 AND kind = 'upload';

-- name: InsertAsset :one
INSERT INTO assets (user_id, library_id, checksum, original_name, original_path, size_bytes)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (user_id, checksum) DO NOTHING
RETURNING id;

-- name: GetAssetIDByChecksum :one
SELECT id FROM assets WHERE user_id = $1 AND checksum = $2;

-- name: GetAsset :one
SELECT * FROM assets WHERE id = $1;

-- name: ListAssets :many
SELECT * FROM assets
WHERE user_id = sqlc.arg('user_id') AND (sqlc.narg('status')::text IS NULL OR status = sqlc.narg('status'))
ORDER BY created_at DESC, id DESC
LIMIT sqlc.arg('row_limit');

-- name: CountAssetStatus :one
SELECT count(*) AS total,
       count(*) FILTER (WHERE status = 'processing') AS processing,
       count(*) FILTER (WHERE status = 'failed') AS failed
FROM assets WHERE user_id = $1;

-- name: FindExistingChecksums :many
SELECT checksum FROM assets WHERE user_id = $1 AND checksum = ANY($2::bytea[]);

-- name: UpdateAssetMetadata :exec
UPDATE assets
SET mime_type = $2, kind = $3, width = $4, height = $5, taken_at = $6, taken_offset_minutes = $7,
    updated_at = now()
WHERE id = $1;

-- name: UpsertExif :exec
INSERT INTO exif (asset_id, make, model, lens, iso, f_number, exposure_time, focal_length, latitude, longitude, raw)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (asset_id) DO UPDATE
SET make = EXCLUDED.make, model = EXCLUDED.model, lens = EXCLUDED.lens, iso = EXCLUDED.iso,
    f_number = EXCLUDED.f_number, exposure_time = EXCLUDED.exposure_time,
    focal_length = EXCLUDED.focal_length, latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude, raw = EXCLUDED.raw;

-- name: UpsertAssetFile :exec
INSERT INTO asset_files (asset_id, kind, path, size_bytes) VALUES ($1, $2, $3, $4)
ON CONFLICT (asset_id, kind) DO UPDATE SET path = EXCLUDED.path, size_bytes = EXCLUDED.size_bytes;

-- name: ListAssetFiles :many
SELECT * FROM asset_files WHERE asset_id = $1 ORDER BY kind;

-- name: MarkAssetReady :exec
UPDATE assets SET status = 'ready', blurhash = $2, error = NULL, updated_at = now() WHERE id = $1;

-- name: MarkAssetFailed :exec
UPDATE assets SET status = 'failed', error = $2, updated_at = now() WHERE id = $1;

-- name: AdminCounts :one
SELECT (SELECT count(*) FROM users) AS users,
       count(*) FILTER (WHERE kind = 'photo') AS photos,
       count(*) FILTER (WHERE kind = 'video') AS videos,
       count(*) FILTER (WHERE status = 'processing') AS processing,
       count(*) FILTER (WHERE status = 'failed') AS failed,
       coalesce(sum(size_bytes), 0)::bigint AS library_bytes
FROM assets;

-- name: DeleteUserAssets :exec
DELETE FROM assets WHERE user_id = $1;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;
