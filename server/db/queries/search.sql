-- name: ListUnanalyzed :many
SELECT a.id FROM assets a
LEFT JOIN asset_search s ON s.asset_id = a.id
WHERE a.status = 'ready' AND a.deleted_at IS NULL AND a.live_photo_of IS NULL AND s.asset_id IS NULL
ORDER BY a.created_at DESC
LIMIT 1000;

-- name: GetAnalysisCounts :one
SELECT count(*) AS total, count(s.asset_id) AS analyzed
FROM assets a LEFT JOIN asset_search s ON s.asset_id = a.id
WHERE a.status = 'ready' AND a.deleted_at IS NULL AND a.live_photo_of IS NULL;

-- name: UpsertAssetSearch :exec
INSERT INTO asset_search (asset_id, embedding, ocr_text)
VALUES (sqlc.arg('asset_id'), sqlc.arg('embedding')::text::vector, sqlc.arg('ocr_text'))
ON CONFLICT (asset_id) DO UPDATE
SET embedding = EXCLUDED.embedding, ocr_text = EXCLUDED.ocr_text, analyzed_at = now();

-- name: DeleteAssetFaces :exec
DELETE FROM faces WHERE asset_id = $1;

-- name: PeopleNearFace :many
-- Reads every face of the user, because an index would stop at the nearest ones and could miss a
-- second person the new face connects to. This runs next to much slower picture analysis.
SELECT p.id, p.name, p.hidden, min(f.embedding <=> sqlc.arg('embedding')::text::vector)::float8 AS distance
FROM faces f
JOIN people p ON p.id = f.person_id
WHERE f.user_id = sqlc.arg('user_id')
  AND f.embedding <=> sqlc.arg('embedding')::text::vector <= sqlc.arg('max_distance')::float8
GROUP BY p.id
ORDER BY distance, p.id;

-- name: PeopleSeenTogether :one
SELECT EXISTS (
    SELECT 1 FROM faces x JOIN faces y ON y.asset_id = x.asset_id
    WHERE x.person_id = sqlc.arg('first') AND y.person_id = sqlc.arg('second')
)::boolean;

-- name: MovePersonRules :exec
UPDATE albums SET rules = jsonb_set(rules, '{person}', to_jsonb(sqlc.arg('target')::uuid::text))
WHERE owner_id = sqlc.arg('user_id') AND rules IS NOT NULL
  AND (rules->>'person')::uuid = ANY(sqlc.arg('sources')::uuid[]);

-- name: CountUserPeople :one
SELECT count(*) FROM people WHERE user_id = $1;

-- name: CreatePerson :one
INSERT INTO people (user_id) VALUES ($1) RETURNING id;

-- name: InsertFace :exec
INSERT INTO faces (asset_id, user_id, person_id, x1, y1, x2, y2, score, embedding)
VALUES (sqlc.arg('asset_id'), sqlc.arg('user_id'), sqlc.arg('person_id'), sqlc.arg('x1'), sqlc.arg('y1'),
        sqlc.arg('x2'), sqlc.arg('y2'), sqlc.arg('score'), sqlc.arg('embedding')::text::vector);

-- name: ListPeople :many
-- Someone seen once and without a name is usually a stranger in the background.
SELECT p.id, p.name, p.hidden, count(DISTINCT a.id) AS asset_count
FROM people p
JOIN faces f ON f.person_id = p.id
JOIN assets a ON a.id = f.asset_id AND a.deleted_at IS NULL AND a.vault_at IS NULL
WHERE p.user_id = $1
GROUP BY p.id, p.name, p.hidden
HAVING p.name <> '' OR count(DISTINCT a.id) >= 2
ORDER BY p.name = '', count(DISTINCT a.id) DESC, p.id;

-- name: GetPerson :one
SELECT id, name, hidden FROM people WHERE id = $1 AND user_id = $2;

-- name: UpdatePerson :exec
UPDATE people SET name = $2, hidden = $3 WHERE id = $1;

-- name: MoveFaces :exec
UPDATE faces SET person_id = sqlc.arg('target') WHERE person_id = ANY(sqlc.arg('sources')::uuid[]) AND user_id = sqlc.arg('user_id');

-- name: DeletePeople :exec
DELETE FROM people WHERE id = ANY(sqlc.arg('ids')::uuid[]) AND user_id = sqlc.arg('user_id');

-- name: PersonCoverFace :one
SELECT f.id, f.x1, f.y1, f.x2, f.y2, fl.path
FROM faces f
JOIN assets a ON a.id = f.asset_id AND a.deleted_at IS NULL AND a.vault_at IS NULL
JOIN asset_files fl ON fl.asset_id = f.asset_id AND fl.kind = 'thumb_large'
WHERE f.person_id = $1
ORDER BY f.score DESC, f.id
LIMIT 1;

-- name: ListAssetPeople :many
SELECT DISTINCT p.id, p.name FROM faces f JOIN people p ON p.id = f.person_id
WHERE f.asset_id = $1 AND p.name <> '' AND NOT p.hidden
ORDER BY p.name, p.id;

-- name: PersonBuckets :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(DISTINCT a.id) AS count
FROM assets a JOIN faces f ON f.asset_id = a.id
WHERE f.person_id = $1 AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
GROUP BY 1
ORDER BY 1 DESC;

-- name: PersonBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a
WHERE a.id IN (SELECT f.asset_id FROM faces f WHERE f.person_id = sqlc.arg('person_id'))
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.local_at DESC, a.id DESC;

-- name: ListDocuments :many
-- What has real text on it: a receipt or a letter, not a sign in the background.
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       false::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a
JOIN asset_search s ON s.asset_id = a.id
WHERE a.user_id = sqlc.arg('user_id') AND a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND length(s.ocr_text) >= sqlc.arg('min_text')::int
ORDER BY a.local_at DESC, a.id DESC
LIMIT sqlc.arg('row_limit');

-- name: ListSearchTerms :many
-- What a query can name: people, places and cameras in this library.
SELECT 'person'::text AS kind, p.name AS value, p.id::text AS ref FROM people p WHERE p.user_id = $1 AND p.name <> ''
UNION
SELECT 'place', x.value, '' FROM (
    SELECT e.city AS value FROM exif e JOIN assets a ON a.id = e.asset_id WHERE a.user_id = $1 AND a.vault_at IS NULL AND a.deleted_at IS NULL AND e.city IS NOT NULL
    UNION SELECT e.state FROM exif e JOIN assets a ON a.id = e.asset_id WHERE a.user_id = $1 AND a.vault_at IS NULL AND a.deleted_at IS NULL AND e.state IS NOT NULL AND e.state <> ''
    UNION SELECT e.country FROM exif e JOIN assets a ON a.id = e.asset_id WHERE a.user_id = $1 AND a.vault_at IS NULL AND a.deleted_at IS NULL AND e.country IS NOT NULL
) x
UNION
SELECT 'camera', x.value, '' FROM (
    SELECT e.make AS value FROM exif e JOIN assets a ON a.id = e.asset_id WHERE a.user_id = $1 AND a.vault_at IS NULL AND a.deleted_at IS NULL AND e.make IS NOT NULL
    UNION SELECT e.model FROM exif e JOIN assets a ON a.id = e.asset_id WHERE a.user_id = $1 AND a.vault_at IS NULL AND a.deleted_at IS NULL AND e.model IS NOT NULL
) x;

-- name: SearchVector :many
SELECT a.id
FROM asset_search s
JOIN assets a ON a.id = s.asset_id
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND (sqlc.narg('from_at')::timestamp IS NULL OR a.local_at >= sqlc.narg('from_at'))
  AND (sqlc.narg('to_at')::timestamp IS NULL OR a.local_at < sqlc.narg('to_at'))
  AND (sqlc.narg('person')::uuid IS NULL OR EXISTS (SELECT 1 FROM faces f WHERE f.asset_id = a.id AND f.person_id = sqlc.narg('person')))
  AND (sqlc.narg('place')::text IS NULL OR lower(sqlc.narg('place')) IN (lower(e.city), lower(e.state), lower(e.country)))
  AND (sqlc.narg('camera')::text IS NULL OR lower(sqlc.narg('camera')) IN (lower(e.make), lower(e.model)))
ORDER BY s.embedding <=> sqlc.arg('embedding')::text::vector
LIMIT sqlc.arg('row_limit');

-- name: SearchText :many
-- Words on the picture and in the file name. Each has its own index, so neither reads every row.
SELECT a.id
FROM assets a
LEFT JOIN asset_search s ON s.asset_id = a.id
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.id IN (
        SELECT o.asset_id FROM asset_search o WHERE o.ocr_tsv @@ plainto_tsquery('simple', sqlc.arg('words'))
        UNION
        SELECT n.id FROM assets n WHERE n.original_name ILIKE sqlc.arg('name_pattern') AND n.user_id = sqlc.arg('user_id')
      )
  AND a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND (sqlc.narg('from_at')::timestamp IS NULL OR a.local_at >= sqlc.narg('from_at'))
  AND (sqlc.narg('to_at')::timestamp IS NULL OR a.local_at < sqlc.narg('to_at'))
  AND (sqlc.narg('person')::uuid IS NULL OR EXISTS (SELECT 1 FROM faces f WHERE f.asset_id = a.id AND f.person_id = sqlc.narg('person')))
  AND (sqlc.narg('place')::text IS NULL OR lower(sqlc.narg('place')) IN (lower(e.city), lower(e.state), lower(e.country)))
  AND (sqlc.narg('camera')::text IS NULL OR lower(sqlc.narg('camera')) IN (lower(e.make), lower(e.model)))
ORDER BY ts_rank(s.ocr_tsv, plainto_tsquery('simple', sqlc.arg('words'))) DESC NULLS LAST, a.local_at DESC
LIMIT sqlc.arg('row_limit');

-- name: SearchFiltered :many
SELECT a.id
FROM assets a
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = sqlc.arg('user_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
  AND (sqlc.narg('from_at')::timestamp IS NULL OR a.local_at >= sqlc.narg('from_at'))
  AND (sqlc.narg('to_at')::timestamp IS NULL OR a.local_at < sqlc.narg('to_at'))
  AND (sqlc.narg('person')::uuid IS NULL OR EXISTS (SELECT 1 FROM faces f WHERE f.asset_id = a.id AND f.person_id = sqlc.narg('person')))
  AND (sqlc.narg('place')::text IS NULL OR lower(sqlc.narg('place')) IN (lower(e.city), lower(e.state), lower(e.country)))
  AND (sqlc.narg('camera')::text IS NULL OR lower(sqlc.narg('camera')) IN (lower(e.make), lower(e.model)))
ORDER BY a.local_at DESC, a.id DESC
LIMIT sqlc.arg('row_limit');

-- name: ItemsByID :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a
WHERE a.id = ANY($1::uuid[]);
