-- name: CreateCastSession :one
INSERT INTO cast_sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3) RETURNING *;

-- name: GetCastSession :one
SELECT * FROM cast_sessions WHERE id = $1 AND user_id = $2 AND expires_at > now();

-- name: DeleteCastSession :execrows
DELETE FROM cast_sessions WHERE id = $1 AND user_id = $2;

-- name: DeleteExpiredCastSessions :exec
DELETE FROM cast_sessions WHERE expires_at <= now();

-- name: CastableAssets :many
-- The assets of a list that this user may show on a TV: visible to them, not in the trash and not in
-- the locked folder, which needs its PIN on every device.
SELECT a.id, a.kind FROM assets a
WHERE a.id = ANY(sqlc.arg('ids')::uuid[]) AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL
  AND asset_visible_to(a.id, sqlc.arg('user_id'));

-- name: AddCastAssets :exec
INSERT INTO cast_session_assets (session_id, asset_id)
SELECT sqlc.arg('session_id'), unnest(sqlc.arg('ids')::uuid[])
ON CONFLICT DO NOTHING;

-- name: CountCastAssets :one
SELECT count(*)::bigint FROM cast_session_assets WHERE session_id = $1;

-- name: GetCastAsset :one
-- An asset reached through a TV's token: only one added to that session, only while it lasts, and
-- only while its user still sees it.
SELECT sqlc.embed(a), s.user_id AS cast_user_id FROM cast_sessions s
JOIN cast_session_assets c ON c.session_id = s.id
JOIN assets a ON a.id = c.asset_id
WHERE s.token_hash = sqlc.arg('token_hash') AND c.asset_id = sqlc.arg('asset_id') AND s.expires_at > now()
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL
  AND asset_visible_to(a.id, s.user_id);

-- name: ListDLNAAlbums :many
-- The albums a TV on the home network sees, when the administrator turns that on: those of one user.
SELECT id, title, updated_at FROM albums WHERE owner_id = $1 AND NOT is_family ORDER BY lower(title), id;

-- name: GetDLNAAlbum :one
SELECT id, title, asset_order FROM albums WHERE id = $1 AND owner_id = $2 AND NOT is_family;

-- name: ListDLNAAlbumAssets :many
SELECT a.id, a.kind, a.mime_type, a.original_name, a.local_at, a.duration_ms, a.size_bytes, a.width, a.height
FROM assets a
WHERE a.id IN (SELECT album_item_ids(sqlc.arg('album_id')::uuid))
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL
  AND asset_visible_to(a.id, sqlc.arg('user_id'))
ORDER BY a.local_at DESC NULLS LAST, a.id
LIMIT sqlc.arg('max')::int OFFSET sqlc.arg('skip')::int;

-- name: CountDLNAAlbumAssets :one
SELECT count(*)::bigint FROM assets a
WHERE a.id IN (SELECT album_item_ids(sqlc.arg('album_id')::uuid))
  AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL
  AND asset_visible_to(a.id, sqlc.arg('user_id'));

-- name: GetDLNAAsset :one
-- An asset a TV asks for: only one in an album of the chosen user.
SELECT a.* FROM assets a
WHERE a.id = sqlc.arg('id') AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL
  AND asset_visible_to(a.id, sqlc.arg('user_id'))
  AND EXISTS (SELECT 1 FROM albums al WHERE al.owner_id = sqlc.arg('user_id') AND NOT al.is_family AND album_has_asset(al.id, a.id));
