-- name: ListFamilyMembers :many
SELECT u.id, u.name, u.email FROM family_members f JOIN users u ON u.id = f.user_id ORDER BY u.name, u.id;

-- name: IsFamilyMember :one
SELECT EXISTS (SELECT 1 FROM family_members WHERE user_id = $1)::boolean;

-- name: AddFamilyMember :exec
INSERT INTO family_members (user_id) VALUES ($1) ON CONFLICT DO NOTHING;

-- name: RemoveFamilyMember :exec
DELETE FROM family_members WHERE user_id = $1;

-- name: JoinFamilyAlbums :exec
INSERT INTO album_members (album_id, user_id, role)
SELECT al.id, sqlc.arg('user_id'), 'viewer' FROM albums al
WHERE al.is_family AND al.owner_id <> sqlc.arg('user_id')
ON CONFLICT DO NOTHING;

-- name: LeaveFamilyAlbums :exec
DELETE FROM album_members m USING albums al WHERE m.album_id = al.id AND al.is_family AND m.user_id = $1;

-- name: DeleteOwnFamilyAlbums :exec
DELETE FROM albums WHERE is_family AND owner_id = $1;

-- name: CreateFamilyAlbum :one
INSERT INTO albums (owner_id, title, rules, is_family) VALUES ($1, $2, $3, true) RETURNING id;

-- name: ShareFamilyAlbum :exec
INSERT INTO album_members (album_id, user_id, role)
SELECT sqlc.arg('album_id'), f.user_id, 'viewer' FROM family_members f
WHERE f.user_id <> sqlc.arg('owner_id')
ON CONFLICT DO NOTHING;

-- name: ListFamilyRules :many
SELECT id, title, rules FROM albums WHERE is_family AND owner_id = $1 ORDER BY created_at;

-- name: DeleteFamilyRule :execrows
DELETE FROM albums WHERE id = $1 AND owner_id = $2 AND is_family;

-- name: FamilyBuckets :many
SELECT to_char(date_trunc('month', a.local_at), 'YYYY-MM')::text AS month, count(*) AS count
FROM assets a
WHERE a.id IN (SELECT album_item_ids(al.id) FROM albums al WHERE al.is_family)
GROUP BY 1
ORDER BY 1 DESC;

-- name: FamilyBucket :many
SELECT a.id, a.user_id, a.kind, a.width, a.height, a.aspect_ratio, a.blurhash, a.is_favorite, a.local_at, a.duration_ms,
       EXISTS (SELECT 1 FROM assets v WHERE v.live_photo_of = a.id AND v.deleted_at IS NULL)::boolean AS is_live,
       0::bigint AS stack_members
FROM assets a
WHERE a.local_at >= sqlc.arg('from_at') AND a.local_at < sqlc.arg('to_at')
  AND a.id IN (SELECT album_item_ids(al.id) FROM albums al WHERE al.is_family)
ORDER BY a.local_at DESC, a.id DESC;
