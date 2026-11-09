-- name: MergeFacts :many
-- What each photo of a duplicate group has, to give the kept one what it lacks.
SELECT a.id, a.is_favorite, a.caption, a.rating, a.taken_at, a.taken_offset_minutes, a.manual_location_none, a.size_bytes,
       e.latitude, e.longitude
FROM assets a
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = $1 AND a.id = ANY($2::uuid[]) AND a.deleted_at IS NULL;

-- name: CopyAlbumMemberships :execrows
INSERT INTO album_assets (album_id, asset_id, added_by, added_at)
SELECT DISTINCT ON (album_id) album_id, sqlc.arg('keep')::uuid, added_by, added_at
FROM album_assets WHERE asset_id = ANY(sqlc.arg('trash')::uuid[])
ORDER BY album_id, added_at
ON CONFLICT DO NOTHING;

-- name: MoveAlbumCovers :exec
UPDATE albums SET cover_asset_id = sqlc.arg('keep')::uuid, updated_at = now()
WHERE cover_asset_id = ANY(sqlc.arg('trash')::uuid[]);

-- name: MoveAlbumComments :exec
UPDATE album_comments SET asset_id = sqlc.arg('keep')::uuid WHERE asset_id = ANY(sqlc.arg('trash')::uuid[]);

-- name: CopyAlbumHearts :exec
INSERT INTO album_hearts (album_id, asset_id, user_id, created_at)
SELECT album_id, sqlc.arg('keep')::uuid, user_id, min(created_at)
FROM album_hearts WHERE asset_id = ANY(sqlc.arg('trash')::uuid[])
GROUP BY album_id, user_id
ON CONFLICT DO NOTHING;

-- name: CopyAssetTags :execrows
INSERT INTO asset_tags (asset_id, tag_id)
SELECT DISTINCT sqlc.arg('keep')::uuid, tag_id FROM asset_tags WHERE asset_id = ANY(sqlc.arg('trash')::uuid[])
ON CONFLICT DO NOTHING;

-- name: MergeOwnFacts :exec
UPDATE assets
SET is_favorite = sqlc.arg('favorite'), caption = sqlc.arg('caption'), rating = sqlc.arg('rating'),
    rating_by_owner = rating_by_owner OR sqlc.arg('rating') <> rating, updated_at = now()
WHERE id = sqlc.arg('id');

-- name: NamedFacesOf :many
SELECT id, asset_id, person_id, x1, y1, x2, y2 FROM faces WHERE asset_id = ANY($1::uuid[]);

-- name: NameFace :exec
UPDATE faces SET person_id = $2 WHERE id = $1 AND person_id IS NULL;

-- name: KeepInCleanup :execrows
UPDATE assets SET cleanup_kept_at = now()
WHERE user_id = $1 AND id = ANY($2::uuid[]) AND cleanup_kept_at IS NULL;
