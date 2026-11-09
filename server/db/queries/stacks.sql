-- name: ListUnorganized :many
SELECT a.id, a.user_id, a.phash, a.local_at
FROM assets a
WHERE a.organized_at IS NULL AND a.kind = 'photo' AND a.status = 'ready'
  AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
ORDER BY a.user_id, a.local_at
LIMIT $1;

-- name: SetFingerprint :exec
UPDATE assets SET phash = $2, sharpness = $3 WHERE id = $1;

-- name: MarkOrganized :exec
UPDATE assets SET organized_at = now() WHERE id = ANY($1::uuid[]);

-- name: ListStackShots :many
SELECT a.id, a.original_name, a.taken_at, a.sharpness, a.stack_parent, a.stack_chosen,
       coalesce(e.make, '')::text AS make, coalesce(e.model, '')::text AS model
FROM assets a
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = $1 AND a.kind = 'photo' AND a.status = 'ready' AND a.taken_at IS NOT NULL AND NOT a.stack_free
  AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.taken_at, a.id;

-- name: ApplyStack :exec
WITH main AS (
    SELECT m.id FROM assets m
    WHERE m.id = sqlc.arg('main_id') AND m.deleted_at IS NULL AND m.archived_at IS NULL AND m.vault_at IS NULL
    FOR UPDATE
)
UPDATE assets a
SET stack_parent = CASE WHEN a.id = main.id THEN NULL ELSE main.id END, updated_at = now()
FROM main
WHERE a.id = ANY(sqlc.arg('ids')::uuid[]) AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND NOT a.stack_free;

-- name: ListStack :many
SELECT a.id
FROM assets a
WHERE (a.id = sqlc.arg('main_id') OR a.stack_parent = sqlc.arg('main_id')) AND a.deleted_at IS NULL
ORDER BY a.stack_parent IS NOT NULL, a.sharpness DESC NULLS LAST, a.id;

-- name: SetStackMain :exec
UPDATE assets a
SET stack_parent = CASE WHEN a.id = sqlc.arg('new_main') THEN NULL ELSE sqlc.arg('new_main')::uuid END,
    stack_chosen = a.id = sqlc.arg('new_main'), updated_at = now()
WHERE a.id = sqlc.arg('old_main') OR a.stack_parent = sqlc.arg('old_main');

-- name: DissolveStack :exec
UPDATE assets SET stack_parent = NULL, stack_free = true, stack_chosen = false, updated_at = now()
WHERE id = sqlc.arg('main_id') OR stack_parent = sqlc.arg('main_id');

-- name: ListHashes :many
SELECT id, phash FROM assets
WHERE user_id = $1 AND phash IS NOT NULL AND kind = 'photo' AND status = 'ready'
  AND deleted_at IS NULL AND vault_at IS NULL AND live_photo_of IS NULL;

-- name: AddSimilarPair :exec
INSERT INTO similar_pairs (a_id, b_id, user_id)
VALUES (LEAST(sqlc.arg('x')::uuid, sqlc.arg('y')::uuid), GREATEST(sqlc.arg('x')::uuid, sqlc.arg('y')::uuid), sqlc.arg('user_id'))
ON CONFLICT DO NOTHING;

-- name: ListUncheckedEmbeddings :many
SELECT s.asset_id, a.user_id, s.embedding
FROM asset_search s
JOIN assets a ON a.id = s.asset_id
WHERE NOT s.similar_checked
LIMIT $1;

-- name: NearestEmbeddings :many
SELECT s.asset_id, (s.embedding <=> sqlc.arg('embedding')::vector)::float8 AS distance
FROM asset_search s
JOIN assets a ON a.id = s.asset_id
WHERE a.user_id = sqlc.arg('user_id') AND s.asset_id <> sqlc.arg('asset_id') AND a.kind = 'photo'
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
ORDER BY s.embedding <=> sqlc.arg('embedding')::vector
LIMIT 5;

-- name: MarkEmbeddingChecked :exec
UPDATE asset_search SET similar_checked = true WHERE asset_id = $1;

-- name: ListSimilarPairs :many
SELECT p.a_id, p.b_id
FROM similar_pairs p
JOIN assets a ON a.id = p.a_id
JOIN assets b ON b.id = p.b_id
WHERE p.user_id = $1 AND p.dismissed_at IS NULL
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.stack_parent IS NULL
  AND b.status = 'ready' AND b.deleted_at IS NULL AND b.archived_at IS NULL AND b.vault_at IS NULL AND b.stack_parent IS NULL;

-- name: ListSimilarItems :many
SELECT a.id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.original_name, a.size_bytes, a.sharpness,
       a.mime_type, a.checksum, a.phash, (a.taken_at IS NOT NULL)::boolean AS has_date, (a.caption <> '')::boolean AS has_caption,
       (e.latitude IS NOT NULL)::boolean AS has_location, coalesce(e.make, '') AS camera_make
FROM assets a
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.id = ANY($1::uuid[]) AND a.user_id = $2;

-- name: DismissSimilar :exec
UPDATE similar_pairs SET dismissed_at = now()
WHERE user_id = $1 AND a_id = ANY($2::uuid[]) AND b_id = ANY($2::uuid[]);

-- name: CountUnorganized :one
SELECT count(*) FROM assets a
WHERE a.user_id = $1 AND a.organized_at IS NULL AND a.kind = 'photo' AND a.status = 'ready'
  AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL;

-- name: ListUnfingerprintedVideos :many
SELECT id, user_id, original_path, duration_ms FROM assets
WHERE kind = 'video' AND vhash IS NULL AND status = 'ready' AND deleted_at IS NULL
  AND vault_at IS NULL AND live_photo_of IS NULL
LIMIT $1;

-- name: SetVideoFingerprint :exec
UPDATE assets SET vhash = $2 WHERE id = $1;

-- name: ListVideoHashes :many
SELECT id, vhash, duration_ms FROM assets
WHERE user_id = $1 AND kind = 'video' AND status = 'ready' AND cardinality(vhash) > 0
  AND deleted_at IS NULL AND vault_at IS NULL AND live_photo_of IS NULL;
