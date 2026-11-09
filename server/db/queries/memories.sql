-- name: OnThisDay :many
SELECT a.id, EXTRACT(YEAR FROM a.local_at)::int AS year
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND EXTRACT(MONTH FROM a.local_at) = sqlc.arg('month')::int AND EXTRACT(DAY FROM a.local_at) = sqlc.arg('day')::int
  AND a.pick <> -1 AND a.screenshot_hint IS NOT TRUE
  AND NOT EXISTS (SELECT 1 FROM exif e WHERE e.asset_id = a.id AND e.raw->>'UserComment' = 'Screenshot')
  AND NOT EXISTS (SELECT 1 FROM similar_pairs p WHERE p.b_id = a.id AND p.dismissed_at IS NULL)
  AND NOT EXISTS (SELECT 1 FROM faces f JOIN memory_hidden_people h ON h.person_id = f.person_id AND h.user_id = a.user_id WHERE f.asset_id = a.id)
  AND a.local_at < sqlc.arg('before')
ORDER BY a.local_at DESC, a.id;

-- name: RecentForSummary :many
SELECT a.id
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND a.pick <> -1 AND a.screenshot_hint IS NOT TRUE
  AND NOT EXISTS (SELECT 1 FROM exif e WHERE e.asset_id = a.id AND e.raw->>'UserComment' = 'Screenshot')
  AND NOT EXISTS (SELECT 1 FROM similar_pairs p WHERE p.b_id = a.id AND p.dismissed_at IS NULL)
  AND NOT EXISTS (SELECT 1 FROM faces f JOIN memory_hidden_people h ON h.person_id = f.person_id AND h.user_id = a.user_id WHERE f.asset_id = a.id)
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

-- name: ListMemoryCandidates :many
-- Everything a memory may be made of. Faces are read separately, and only named people matter there.
SELECT a.id, a.local_at, a.is_favorite, a.rating, a.sharpness,
       e.latitude, e.longitude, COALESCE(e.city, '')::text AS city, COALESCE(e.country, '')::text AS country
FROM assets a LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND a.pick <> -1 AND a.screenshot_hint IS NOT TRUE
  AND COALESCE(e.raw->>'UserComment', '') <> 'Screenshot'
  AND NOT EXISTS (SELECT 1 FROM similar_pairs p WHERE p.b_id = a.id AND p.dismissed_at IS NULL)
ORDER BY a.local_at, a.id;

-- name: ListMemoryFaces :many
SELECT f.asset_id, f.person_id FROM faces f
WHERE f.user_id = $1 AND f.person_id IS NOT NULL;

-- name: ListMemoryPeople :many
SELECT p.id, p.name, p.birth_date FROM people p
WHERE p.user_id = $1 AND p.name <> '' AND NOT p.hidden;

-- name: ListMemoryHiddenPeopleIDs :many
SELECT person_id FROM memory_hidden_people WHERE user_id = $1;

-- name: ClearComputedMemories :exec
DELETE FROM memories WHERE user_id = $1 AND hidden_at IS NULL;

-- name: UpsertMemory :exec
-- What was hidden stays hidden when the same memory is worked out again.
INSERT INTO memories (user_id, kind, key, title, title_params, items, rank, shown_from, shown_until)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
ON CONFLICT (user_id, kind, key) DO UPDATE
SET title = EXCLUDED.title, title_params = EXCLUDED.title_params, items = EXCLUDED.items, rank = EXCLUDED.rank,
    shown_from = EXCLUDED.shown_from, shown_until = EXCLUDED.shown_until;

-- name: SetMemoryRun :exec
INSERT INTO memory_runs (user_id, computed_for) VALUES ($1, $2)
ON CONFLICT (user_id) DO UPDATE SET computed_for = EXCLUDED.computed_for;

-- name: GetMemoryRun :one
SELECT computed_for FROM memory_runs WHERE user_id = $1;

-- name: ListDueMemories :many
SELECT kind, key, title, title_params, items FROM memories
WHERE user_id = sqlc.arg('user_id') AND hidden_at IS NULL
  AND shown_from <= sqlc.arg('day')::date AND shown_until >= sqlc.arg('day')::date
ORDER BY rank, key;

-- name: FilterMemoryItems :many
-- A photo can have gone to the trash or the vault since the memory was worked out.
SELECT a.id FROM assets a
WHERE a.id = ANY(sqlc.arg('ids')::uuid[]) AND a.user_id = sqlc.arg('user_id') AND a.status = 'ready'
  AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.pick <> -1
  AND NOT EXISTS (SELECT 1 FROM faces f JOIN memory_hidden_people h ON h.person_id = f.person_id AND h.user_id = a.user_id WHERE f.asset_id = a.id);

-- name: ListHiddenMemoryKeys :many
SELECT kind, key FROM memories WHERE user_id = $1 AND hidden_at IS NOT NULL;

-- name: HideMemory :exec
INSERT INTO memories (user_id, kind, key, hidden_at) VALUES ($1, $2, $3, now())
ON CONFLICT (user_id, kind, key) DO UPDATE SET hidden_at = now();

-- name: ShowMemory :exec
UPDATE memories SET hidden_at = NULL WHERE user_id = $1 AND kind = $2 AND key = $3;

-- name: ShowAllMemories :exec
UPDATE memories SET hidden_at = NULL WHERE user_id = $1 AND hidden_at IS NOT NULL;

-- name: HideMemoryPerson :exec
INSERT INTO memory_hidden_people (user_id, person_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;

-- name: ShowMemoryPerson :exec
DELETE FROM memory_hidden_people WHERE user_id = $1 AND person_id = $2;

-- name: ListMemoryHiddenPeople :many
SELECT p.id, p.name FROM memory_hidden_people h JOIN people p ON p.id = h.person_id
WHERE h.user_id = $1 ORDER BY p.name, p.id;
