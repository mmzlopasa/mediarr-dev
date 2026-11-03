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
WHERE user_id = sqlc.arg('user_id') AND deleted_at IS NULL
  AND (sqlc.narg('status')::text IS NULL OR status = sqlc.narg('status'))
ORDER BY created_at DESC, id DESC
LIMIT sqlc.arg('row_limit');

-- name: CountAssetStatus :one
SELECT count(*) AS total,
       count(*) FILTER (WHERE status = 'processing') AS processing,
       count(*) FILTER (WHERE status = 'failed') AS failed
FROM assets WHERE user_id = $1 AND deleted_at IS NULL;

-- name: FindExistingChecksums :many
SELECT checksum FROM assets WHERE user_id = $1 AND deleted_at IS NULL AND checksum = ANY($2::bytea[]);

-- name: UpdateAssetMetadata :exec
UPDATE assets
SET mime_type = $2, kind = $3, width = $4, height = $5, taken_at = $6, taken_offset_minutes = $7,
    content_id = $8, updated_at = now()
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
UPDATE assets SET status = 'ready', blurhash = $2, aspect_ratio = $3, error = NULL, updated_at = now() WHERE id = $1;

-- name: MarkAssetFailed :exec
UPDATE assets SET status = 'failed', error = $2, updated_at = now() WHERE id = $1;

-- name: AdminCounts :one
SELECT (SELECT count(*) FROM users) AS users,
       count(*) FILTER (WHERE kind = 'photo') AS photos,
       count(*) FILTER (WHERE kind = 'video' AND live_photo_of IS NULL) AS videos,
       count(*) FILTER (WHERE status = 'processing') AS processing,
       count(*) FILTER (WHERE status = 'failed') AS failed,
       coalesce(sum(size_bytes), 0)::bigint AS library_bytes
FROM assets WHERE deleted_at IS NULL;

-- name: DeleteUserAssets :exec
DELETE FROM assets WHERE user_id = $1;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;

-- name: RestoreDeletedAsset :exec
UPDATE assets SET deleted_at = NULL, updated_at = now() WHERE id = $1 AND deleted_at IS NOT NULL;

-- name: TimelineBuckets :many
SELECT to_char(date_trunc('month', local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets
WHERE user_id = $1 AND status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND live_photo_of IS NULL
GROUP BY 1
ORDER BY 1 DESC;

-- name: TimelineBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live
FROM assets a
WHERE a.user_id = $1 AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.live_photo_of IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.local_at DESC, a.id DESC;

-- name: GetOwnedAsset :one
SELECT * FROM assets WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL;

-- name: NewerAsset :one
SELECT id FROM assets
WHERE user_id = $1 AND status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND live_photo_of IS NULL
  AND (local_at, id) > (sqlc.arg('local_at')::timestamp, sqlc.arg('id')::uuid)
ORDER BY local_at ASC, id ASC LIMIT 1;

-- name: OlderAsset :one
SELECT id FROM assets
WHERE user_id = $1 AND status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND live_photo_of IS NULL
  AND (local_at, id) < (sqlc.arg('local_at')::timestamp, sqlc.arg('id')::uuid)
ORDER BY local_at DESC, id DESC LIMIT 1;

-- name: GetExif :one
SELECT * FROM exif WHERE asset_id = $1;

-- name: GetOwnedAssetFile :one
SELECT f.path FROM asset_files f JOIN assets a ON a.id = f.asset_id
WHERE f.asset_id = $1 AND f.kind = $2 AND a.user_id = $3 AND a.deleted_at IS NULL;

-- name: ListOwnedAssets :many
SELECT * FROM assets WHERE user_id = $1 AND deleted_at IS NULL AND id = ANY(sqlc.arg('ids')::uuid[]);

-- name: SetFavorite :execrows
UPDATE assets SET is_favorite = $3, updated_at = now()
WHERE user_id = $1 AND deleted_at IS NULL AND id = ANY($2::uuid[]);

-- name: ArchiveAssets :execrows
UPDATE assets SET archived_at = now(), updated_at = now()
WHERE user_id = $1 AND deleted_at IS NULL AND archived_at IS NULL AND id = ANY($2::uuid[]);

-- name: SoftDeleteAssets :execrows
UPDATE assets SET deleted_at = now(), updated_at = now()
WHERE user_id = $1 AND deleted_at IS NULL AND id = ANY($2::uuid[]);

-- name: UpdateVideoInfo :exec
UPDATE assets SET duration_ms = $2, video_codec = $3, updated_at = now() WHERE id = $1;

-- name: UpdateSprite :exec
UPDATE assets SET sprite_columns = $2, sprite_rows = $3, sprite_count = $4, sprite_interval_ms = $5, updated_at = now()
WHERE id = $1;

-- name: LinkLivePhoto :exec
UPDATE assets v SET live_photo_of = p.id, updated_at = now()
FROM assets p
WHERE v.user_id = $1 AND p.user_id = $1 AND v.content_id = $2 AND p.content_id = $2
  AND v.kind = 'video' AND p.kind = 'photo' AND v.id <> p.id AND p.deleted_at IS NULL;

-- name: GetLiveVideo :one
SELECT id FROM assets WHERE live_photo_of = $1 AND deleted_at IS NULL AND status = 'ready' LIMIT 1;

-- name: GetAssetFile :one
SELECT path FROM asset_files WHERE asset_id = $1 AND kind = $2;

-- name: ListReadyAssetIDs :many
SELECT id FROM assets WHERE status = 'ready' AND deleted_at IS NULL;
