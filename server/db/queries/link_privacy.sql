-- name: SetLinkPrivacy :one
UPDATE share_links
SET show_location = sqlc.arg('show_location'), hide_faces = sqlc.arg('hide_faces'),
    strip_camera = sqlc.arg('strip_camera'), strip_date = sqlc.arg('strip_date'),
    ask_name = sqlc.arg('ask_name'), privacy_version = privacy_version + 1
WHERE id = sqlc.arg('id') AND album_id = sqlc.arg('album_id')
RETURNING *;

-- name: ClearLinkVisiblePeople :exec
DELETE FROM share_link_visible_people WHERE link_id = $1;

-- name: AddLinkVisiblePeople :exec
-- Only the album owner's own people can be named.
INSERT INTO share_link_visible_people (link_id, person_id)
SELECT sqlc.arg('link_id'), p.id FROM people p
WHERE p.id = ANY(sqlc.arg('people')::uuid[]) AND p.user_id = sqlc.arg('owner_id')
ON CONFLICT DO NOTHING;

-- name: ListLinkVisiblePeople :many
SELECT person_id FROM share_link_visible_people WHERE link_id = $1;

-- name: LinkVisitStats :many
SELECT link_id, count(*)::int AS visits, max(at)::timestamptz AS last_at
FROM share_link_visits
WHERE link_id = ANY($1::uuid[]) AND at > now() - interval '90 days'
GROUP BY link_id;

-- name: RecordLinkVisit :one
-- A visitor is one browser: opening the link again is the same visit.
INSERT INTO share_link_visits (link_id, visitor_hash, city, country, device)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (link_id, visitor_hash) DO UPDATE SET at = share_link_visits.at
RETURNING id, (xmax = 0)::boolean AS fresh;

-- name: CountAllLinkVisits :one
SELECT count(*) FROM share_link_visits WHERE link_id = $1;

-- name: NameLinkVisit :execrows
UPDATE share_link_visits SET name = $3 WHERE link_id = $1 AND visitor_hash = $2;

-- name: LinkVisitNamed :one
SELECT name <> '' FROM share_link_visits WHERE link_id = $1 AND visitor_hash = $2;

-- name: CountLinkVisitView :exec
UPDATE share_link_visits SET viewed = viewed + 1 WHERE link_id = $1 AND visitor_hash = $2;

-- name: CountLinkVisitDownload :exec
UPDATE share_link_visits SET downloaded = downloaded + 1 WHERE link_id = $1 AND visitor_hash = $2;

-- name: ListLinkVisits :many
SELECT at, name, city, country, device, viewed, downloaded
FROM share_link_visits
WHERE link_id = $1 AND at > now() - interval '90 days'
ORDER BY at DESC
LIMIT 500;

-- name: DeleteOldLinkVisits :exec
DELETE FROM share_link_visits WHERE at < now() - interval '90 days';

-- name: GetAlbumLink :one
SELECT * FROM share_links WHERE id = $1 AND album_id = $2;

-- name: AlbumPrivacyFacts :one
SELECT count(*) FILTER (WHERE a.kind = 'photo')::int AS photos,
       count(*) FILTER (WHERE a.kind = 'photo' AND NOT EXISTS (
           SELECT 1 FROM asset_search s WHERE s.asset_id = a.id AND s.analyzed_at IS NOT NULL))::int AS unchecked,
       count(*) FILTER (WHERE a.kind = 'video')::int AS videos
FROM assets a
WHERE a.status = 'ready' AND a.deleted_at IS NULL AND a.live_photo_of IS NULL
  AND album_has_asset(sqlc.arg('album_id'), a.id);

-- name: FacesToBlur :many
-- The faces of a picture, but those of the people who may be seen.
SELECT f.x1, f.y1, f.x2, f.y2 FROM faces f
WHERE f.asset_id = sqlc.arg('asset_id')
  AND (f.person_id IS NULL OR NOT f.person_id = ANY(sqlc.arg('visible')::uuid[]));
