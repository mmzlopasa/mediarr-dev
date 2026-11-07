-- name: CollectionBuckets :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.live_photo_of IS NULL
  AND CASE sqlc.arg('scope')::text
        WHEN 'favorites' THEN a.is_favorite AND a.deleted_at IS NULL AND a.vault_at IS NULL
        WHEN 'archive' THEN a.archived_at IS NOT NULL AND a.deleted_at IS NULL AND a.vault_at IS NULL
        WHEN 'trash' THEN a.deleted_at IS NOT NULL AND a.vault_at IS NULL
        WHEN 'vault' THEN a.vault_at IS NOT NULL AND a.deleted_at IS NULL
        ELSE false END
GROUP BY 1
ORDER BY 1 DESC;

-- name: CollectionBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id)::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.live_photo_of IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
  AND CASE sqlc.arg('scope')::text
        WHEN 'favorites' THEN a.is_favorite AND a.deleted_at IS NULL AND a.vault_at IS NULL
        WHEN 'archive' THEN a.archived_at IS NOT NULL AND a.deleted_at IS NULL AND a.vault_at IS NULL
        WHEN 'trash' THEN a.deleted_at IS NOT NULL AND a.vault_at IS NULL
        WHEN 'vault' THEN a.vault_at IS NOT NULL AND a.deleted_at IS NULL
        ELSE false END
ORDER BY a.local_at DESC, a.id DESC;

-- name: GetCollectionAsset :one
-- A Live Photo's video follows its photo.
SELECT a.*
FROM assets a
JOIN assets p ON p.id = COALESCE(a.live_photo_of, a.id)
WHERE a.id = sqlc.arg('id') AND a.user_id = sqlc.arg('user_id')
  AND CASE sqlc.arg('scope')::text
        WHEN 'favorites' THEN p.is_favorite AND p.deleted_at IS NULL AND p.vault_at IS NULL
        WHEN 'archive' THEN p.archived_at IS NOT NULL AND p.deleted_at IS NULL AND p.vault_at IS NULL
        WHEN 'trash' THEN p.deleted_at IS NOT NULL AND p.vault_at IS NULL
        WHEN 'vault' THEN p.vault_at IS NOT NULL AND p.deleted_at IS NULL
        WHEN 'recent' THEN p.deleted_at IS NULL AND p.vault_at IS NULL AND p.archived_at IS NULL
        ELSE false END;

-- name: UnarchiveAssets :execrows
UPDATE assets SET archived_at = NULL, updated_at = now()
WHERE user_id = $1 AND archived_at IS NOT NULL AND deleted_at IS NULL AND vault_at IS NULL AND id = ANY($2::uuid[]);

-- name: RestoreAssets :execrows
UPDATE assets SET deleted_at = NULL, updated_at = now()
WHERE user_id = $1 AND deleted_at IS NOT NULL AND id = ANY($2::uuid[]);

-- name: MoveToVault :execrows
UPDATE assets SET vault_at = now(), updated_at = now()
WHERE user_id = $1 AND deleted_at IS NULL AND vault_at IS NULL
  AND (id = ANY($2::uuid[]) OR live_photo_of = ANY($2::uuid[]));

-- name: MoveOutOfVault :execrows
UPDATE assets SET vault_at = NULL, updated_at = now()
WHERE user_id = $1 AND vault_at IS NOT NULL
  AND (id = ANY($2::uuid[]) OR live_photo_of = ANY($2::uuid[]));

-- name: ListPurgeable :many
SELECT id FROM assets
WHERE user_id = sqlc.arg('user_id') AND id = ANY(sqlc.arg('ids')::uuid[])
  AND ((deleted_at IS NOT NULL AND vault_at IS NULL) OR (sqlc.arg('in_vault')::boolean AND vault_at IS NOT NULL));

-- name: ListTrash :many
SELECT id FROM assets WHERE user_id = $1 AND deleted_at IS NOT NULL AND vault_at IS NULL LIMIT 1000;

-- name: ListExpiredTrash :many
SELECT id FROM assets WHERE deleted_at < sqlc.arg('before') ORDER BY deleted_at LIMIT 500;

-- name: ListPurgeFamily :many
-- The photos, with the videos of Live Photos, which would otherwise surface on the timeline.
SELECT a.*, l.kind AS library_kind
FROM assets a JOIN libraries l ON l.id = a.library_id
WHERE a.id = ANY($1::uuid[]) OR a.live_photo_of = ANY($1::uuid[]);

-- name: DeleteAssetsByID :exec
DELETE FROM assets WHERE id = ANY($1::uuid[]);

-- name: SetVaultPin :exec
UPDATE users SET vault_pin_hash = $2, updated_at = now() WHERE id = $1;

-- name: CreateVaultSession :exec
INSERT INTO vault_sessions (token_hash, user_id, expires_at) VALUES ($1, $2, $3);

-- name: VaultSessionValid :one
SELECT EXISTS (
    SELECT 1 FROM vault_sessions WHERE token_hash = $1 AND user_id = $2 AND expires_at > now()
)::boolean;

-- name: DeleteVaultSessions :exec
DELETE FROM vault_sessions WHERE user_id = $1;

-- name: DeleteExpiredVaultSessions :exec
DELETE FROM vault_sessions WHERE expires_at <= now();

-- name: ListTags :many
SELECT t.id, t.name, count(a.id) AS asset_count
FROM tags t
LEFT JOIN asset_tags x ON x.tag_id = t.id
LEFT JOIN assets a ON a.id = x.asset_id AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
WHERE t.user_id = $1
GROUP BY t.id, t.name
ORDER BY lower(t.name), t.id;

-- name: EnsureTag :one
INSERT INTO tags (user_id, name) VALUES ($1, $2)
ON CONFLICT (user_id, lower(name)) DO UPDATE SET name = tags.name
RETURNING id;

-- name: GetTag :one
SELECT id, name FROM tags WHERE id = $1 AND user_id = $2;

-- name: DeleteTag :execrows
DELETE FROM tags WHERE id = $1 AND user_id = $2;

-- name: TagAssets :execrows
INSERT INTO asset_tags (asset_id, tag_id)
SELECT a.id, sqlc.arg('tag_id') FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.id = ANY(sqlc.arg('ids')::uuid[])
ON CONFLICT DO NOTHING;

-- name: UntagAssets :execrows
DELETE FROM asset_tags x USING assets a, tags t
WHERE x.asset_id = a.id AND x.tag_id = t.id AND a.user_id = sqlc.arg('user_id')
  AND a.id = ANY(sqlc.arg('ids')::uuid[]) AND lower(t.name) = lower(sqlc.arg('name'));

-- name: ListAssetTags :many
SELECT t.name FROM asset_tags x JOIN tags t ON t.id = x.tag_id WHERE x.asset_id = $1 ORDER BY lower(t.name);

-- name: TagBuckets :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a JOIN asset_tags x ON x.asset_id = a.id
WHERE x.tag_id = $1 AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
GROUP BY 1
ORDER BY 1 DESC;

-- name: TagBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a JOIN asset_tags x ON x.asset_id = a.id
WHERE x.tag_id = sqlc.arg('tag_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.local_at DESC, a.id DESC;

-- name: TrashSummary :one
SELECT count(*) AS assets, coalesce(sum(size_bytes), 0)::bigint AS bytes
FROM assets WHERE user_id = $1 AND deleted_at IS NOT NULL AND live_photo_of IS NULL;

-- name: CountOwnedOfIDs :one
SELECT count(*) FROM assets WHERE user_id = $1 AND id = ANY($2::uuid[]);

-- name: FindTagByName :one
SELECT id, name FROM tags WHERE user_id = $1 AND lower(name) = lower(sqlc.arg('name'));

-- name: RenameTag :exec
UPDATE tags SET name = $3 WHERE id = $1 AND user_id = $2;

-- name: MoveTagAssets :exec
-- The photos of one tag get another, before the first goes.
INSERT INTO asset_tags (asset_id, tag_id)
SELECT x.asset_id, sqlc.arg('into')::uuid FROM asset_tags x WHERE x.tag_id = sqlc.arg('from')::uuid
ON CONFLICT DO NOTHING;

-- name: RecentBuckets :many
-- Recently added goes by when a photo reached the server, not when it was taken.
SELECT to_char(date_trunc('month', a.created_at AT TIME ZONE 'UTC'), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a
WHERE a.user_id = $1 AND a.status = 'ready' AND a.live_photo_of IS NULL
  AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.archived_at IS NULL
GROUP BY 1
ORDER BY 1 DESC;

-- name: RecentBucket :many
-- local_at carries the time it was added, so the days in the grid are the days things came in.
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite,
       (a.created_at AT TIME ZONE 'UTC')::timestamp AS local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id)::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.live_photo_of IS NULL
  AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.archived_at IS NULL
  AND a.created_at >= (sqlc.arg('from_at')::timestamp AT TIME ZONE 'UTC')
  AND a.created_at < (sqlc.arg('to_at')::timestamp AT TIME ZONE 'UTC')
ORDER BY a.created_at DESC, a.id DESC;
