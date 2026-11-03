-- name: OnThisDay :many
SELECT a.id, EXTRACT(YEAR FROM a.local_at)::int AS year
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND EXTRACT(MONTH FROM a.local_at) = sqlc.arg('month')::int AND EXTRACT(DAY FROM a.local_at) = sqlc.arg('day')::int
  AND a.local_at < sqlc.arg('before')
ORDER BY a.local_at DESC, a.id;

-- name: RecentForSummary :many
SELECT a.id
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.is_favorite DESC, a.local_at DESC, a.id
LIMIT 200;

-- name: CreateStoryExport :one
INSERT INTO story_exports (user_id, title) VALUES ($1, $2) RETURNING id;

-- name: GetStoryExport :one
SELECT * FROM story_exports WHERE id = $1 AND user_id = $2;

-- name: FinishStoryExport :exec
UPDATE story_exports SET status = $2, path = $3 WHERE id = $1;

-- name: ListOldStoryExports :many
SELECT id, path FROM story_exports WHERE created_at < $1;

-- name: DeleteStoryExport :exec
DELETE FROM story_exports WHERE id = $1;

-- name: ListStoryPictures :many
-- In the order asked for, and only what this user may see.
SELECT a.id, f.path
FROM assets a JOIN asset_files f ON f.asset_id = a.id AND f.kind = 'thumb_large'
WHERE a.id = ANY(sqlc.arg('ids')::uuid[]) AND asset_visible_to(a.id, sqlc.arg('user_id'));
