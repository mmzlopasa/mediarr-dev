-- name: CreateAlbum :one
INSERT INTO albums (owner_id, title, description, rules) VALUES ($1, $2, $3, $4) RETURNING id;

-- name: ListAlbums :many
SELECT al.id, al.owner_id, al.title, al.description, al.cover_asset_id, al.asset_order, al.rules, al.created_at, al.updated_at,
       COALESCE(m.role, 'owner')::text AS role, u.name AS owner_name,
       album_asset_count(al.id)::bigint AS asset_count,
       album_newest_asset(al.id) AS newest_asset_id,
       (SELECT n.local_at FROM assets n WHERE n.id = album_newest_asset(al.id)) AS newest_at
FROM albums al
JOIN users u ON u.id = al.owner_id
LEFT JOIN album_members m ON m.album_id = al.id AND m.user_id = sqlc.arg('user_id')
WHERE al.owner_id = sqlc.arg('user_id') OR m.user_id IS NOT NULL
ORDER BY al.updated_at DESC, al.id;

-- name: GetAlbumForUser :one
SELECT al.id, al.owner_id, al.title, al.description, al.cover_asset_id, al.asset_order, al.rules, al.created_at, al.updated_at,
       COALESCE(m.role, 'owner')::text AS role, u.name AS owner_name,
       album_asset_count(al.id)::bigint AS asset_count,
       album_newest_asset(al.id) AS newest_asset_id,
       (SELECT n.local_at FROM assets n WHERE n.id = album_newest_asset(al.id)) AS newest_at
FROM albums al
JOIN users u ON u.id = al.owner_id
LEFT JOIN album_members m ON m.album_id = al.id AND m.user_id = sqlc.arg('user_id')
WHERE al.id = sqlc.arg('id') AND (al.owner_id = sqlc.arg('user_id') OR m.user_id IS NOT NULL);

-- name: UpdateAlbum :exec
UPDATE albums SET title = $2, description = $3, cover_asset_id = $4, asset_order = $5, rules = $6, updated_at = now()
WHERE id = $1;

-- name: DeleteAlbum :exec
DELETE FROM albums WHERE id = $1;

-- name: TouchAlbum :exec
UPDATE albums SET updated_at = now() WHERE id = $1;

-- name: AddAlbumAssets :execrows
INSERT INTO album_assets (album_id, asset_id, added_by)
SELECT sqlc.arg('album_id'), a.id, sqlc.arg('user_id')
FROM assets a
WHERE a.user_id = sqlc.arg('user_id') AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.id = ANY(sqlc.arg('ids')::uuid[])
ON CONFLICT DO NOTHING;

-- name: RemoveAlbumAssets :execrows
DELETE FROM album_assets WHERE album_id = $1 AND asset_id = ANY($2::uuid[]);

-- name: RemoveOwnAlbumAssets :execrows
DELETE FROM album_assets WHERE album_id = $1 AND asset_id = ANY($2::uuid[]) AND added_by = $3;

-- name: AlbumHasAsset :one
SELECT album_has_asset($1, $2)::boolean;

-- name: ListAlbumMembers :many
SELECT m.user_id, m.role, u.name FROM album_members m JOIN users u ON u.id = m.user_id
WHERE m.album_id = $1 ORDER BY u.name, m.user_id;

-- name: SetAlbumMember :exec
INSERT INTO album_members (album_id, user_id, role) VALUES ($1, $2, $3)
ON CONFLICT (album_id, user_id) DO UPDATE SET role = EXCLUDED.role;

-- name: RemoveAlbumMember :execrows
DELETE FROM album_members WHERE album_id = $1 AND user_id = $2;

-- name: UserExists :one
SELECT EXISTS (SELECT 1 FROM users WHERE id = $1)::boolean;

-- name: ListDirectory :many
SELECT id, name FROM users WHERE id <> $1 ORDER BY name, id;

-- name: AlbumBuckets :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a
WHERE a.id IN (SELECT album_item_ids($1))
GROUP BY 1
ORDER BY 1 DESC;

-- name: AlbumBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live
FROM assets a
WHERE a.id IN (SELECT album_item_ids(sqlc.arg('album_id')))
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.local_at DESC, a.id DESC;

-- name: ListCameras :many
SELECT DISTINCT trim(coalesce(e.make, '') || ' ' || coalesce(e.model, ''))::text AS camera
FROM exif e JOIN assets a ON a.id = e.asset_id
WHERE a.user_id = $1 AND a.deleted_at IS NULL AND a.vault_at IS NULL AND (e.make IS NOT NULL OR e.model IS NOT NULL)
ORDER BY 1;

-- name: ListComments :many
SELECT c.id, c.asset_id, c.user_id, c.body, c.created_at, u.name
FROM album_comments c JOIN users u ON u.id = c.user_id
WHERE c.album_id = sqlc.arg('album_id')
  AND (c.asset_id = sqlc.narg('asset_id') OR (sqlc.narg('asset_id')::uuid IS NULL AND c.asset_id IS NULL))
ORDER BY c.created_at, c.id;

-- name: CreateComment :one
INSERT INTO album_comments (album_id, asset_id, user_id, body) VALUES ($1, $2, $3, $4) RETURNING id;

-- name: GetComment :one
SELECT user_id FROM album_comments WHERE id = $1 AND album_id = $2;

-- name: DeleteComment :exec
DELETE FROM album_comments WHERE id = $1;

-- name: SetHeart :exec
INSERT INTO album_hearts (album_id, asset_id, user_id) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING;

-- name: RemoveHeart :exec
DELETE FROM album_hearts WHERE album_id = $1 AND asset_id = $2 AND user_id = $3;

-- name: CountHearts :one
SELECT count(*) AS total, count(*) FILTER (WHERE user_id = sqlc.arg('user_id')) AS mine
FROM album_hearts WHERE album_id = sqlc.arg('album_id') AND asset_id = sqlc.arg('asset_id');

-- name: ListPartnersGiven :many
SELECT ps.partner_id AS user_id, u.name, ps.since_at, ps.in_timeline
FROM partner_shares ps JOIN users u ON u.id = ps.partner_id WHERE ps.owner_id = $1 ORDER BY u.name, ps.partner_id;

-- name: ListPartnersReceived :many
SELECT ps.owner_id AS user_id, u.name, ps.since_at, ps.in_timeline
FROM partner_shares ps JOIN users u ON u.id = ps.owner_id WHERE ps.partner_id = $1 ORDER BY u.name, ps.owner_id;

-- name: SetPartner :exec
INSERT INTO partner_shares (owner_id, partner_id, since_at) VALUES ($1, $2, $3)
ON CONFLICT (owner_id, partner_id) DO UPDATE SET since_at = EXCLUDED.since_at;

-- name: RemovePartner :execrows
DELETE FROM partner_shares WHERE owner_id = $1 AND partner_id = $2;

-- name: SetPartnerTimeline :execrows
UPDATE partner_shares SET in_timeline = $3 WHERE owner_id = $1 AND partner_id = $2;

-- name: GetPartnerShare :one
SELECT since_at FROM partner_shares WHERE owner_id = $1 AND partner_id = $2;

-- name: CountTimelinePartners :one
SELECT count(*) FROM partner_shares WHERE partner_id = $1 AND in_timeline;

-- name: PartnerBuckets :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a
WHERE a.user_id = sqlc.arg('owner_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND (sqlc.narg('since_at')::timestamp IS NULL OR a.local_at >= sqlc.narg('since_at'))
GROUP BY 1
ORDER BY 1 DESC;

-- name: PartnerBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live
FROM assets a
WHERE a.user_id = sqlc.arg('owner_id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND (sqlc.narg('since_at')::timestamp IS NULL OR a.local_at >= sqlc.narg('since_at'))
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
ORDER BY a.local_at DESC, a.id DESC;

-- name: TimelineBucketsWithPartners :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a
WHERE a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND (a.user_id = $1 OR EXISTS (
      SELECT 1 FROM partner_shares ps
      WHERE ps.owner_id = a.user_id AND ps.partner_id = $1 AND ps.in_timeline
        AND (ps.since_at IS NULL OR a.local_at >= ps.since_at)))
GROUP BY 1
ORDER BY 1 DESC;

-- name: TimelineBucketWithPartners :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live
FROM assets a
WHERE a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
  AND (a.user_id = sqlc.arg('user_id') OR EXISTS (
      SELECT 1 FROM partner_shares ps
      WHERE ps.owner_id = a.user_id AND ps.partner_id = sqlc.arg('user_id') AND ps.in_timeline
        AND (ps.since_at IS NULL OR a.local_at >= ps.since_at)))
ORDER BY a.local_at DESC, a.id DESC;

-- name: CreateLink :one
INSERT INTO share_links (album_id, token_hash, label, password_hash, expires_at, download_limit, allow_download, allow_upload, upload_only, show_location, watermark)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
RETURNING *;

-- name: ListLinks :many
SELECT * FROM share_links WHERE album_id = $1 ORDER BY created_at DESC, id;

-- name: DeleteLink :execrows
DELETE FROM share_links WHERE id = $1 AND album_id = $2;

-- name: GetLinkByToken :one
SELECT l.*, al.title, al.description, al.owner_id, al.asset_order, (al.rules IS NOT NULL)::boolean AS is_smart
FROM share_links l JOIN albums al ON al.id = l.album_id
WHERE l.token_hash = $1 AND (l.expires_at IS NULL OR l.expires_at > now());

-- name: CreateLinkSession :exec
INSERT INTO share_link_sessions (token_hash, link_id, expires_at) VALUES ($1, $2, $3);

-- name: DeleteExpiredLinkSessions :exec
DELETE FROM share_link_sessions WHERE expires_at <= now();

-- name: LinkSessionValid :one
SELECT EXISTS (
    SELECT 1 FROM share_link_sessions WHERE token_hash = $1 AND link_id = $2 AND expires_at > now()
)::boolean;

-- name: CountLinkDownload :execrows
UPDATE share_links SET download_count = download_count + 1
WHERE id = $1 AND allow_download AND (download_limit IS NULL OR download_count < download_limit);

-- name: GetVisibleAsset :one
SELECT * FROM assets WHERE id = $1 AND asset_visible_to(id, sqlc.arg('user_id'));

-- name: GetVisibleAssetFile :one
SELECT f.path FROM asset_files f
WHERE f.asset_id = sqlc.arg('asset_id') AND f.kind = sqlc.arg('kind') AND asset_visible_to(f.asset_id, sqlc.arg('user_id'));

-- name: ListVisibleAssets :many
SELECT * FROM assets WHERE id = ANY(sqlc.arg('ids')::uuid[]) AND asset_visible_to(id, sqlc.arg('user_id'));

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1;
