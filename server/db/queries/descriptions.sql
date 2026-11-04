-- name: UpsertDescription :exec
INSERT INTO asset_descriptions (asset_id, description, model) VALUES ($1, $2, $3)
ON CONFLICT (asset_id) DO UPDATE SET description = EXCLUDED.description, model = EXCLUDED.model, created_at = now();

-- name: GetDescription :one
SELECT description FROM asset_descriptions WHERE asset_id = $1;

-- name: ListUndescribed :many
SELECT a.id FROM assets a
LEFT JOIN asset_descriptions d ON d.asset_id = a.id
WHERE d.asset_id IS NULL AND a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL
  AND a.vault_at IS NULL AND a.live_photo_of IS NULL
ORDER BY a.local_at DESC, a.id
LIMIT $1;

-- name: DescriptionProgress :one
SELECT (SELECT count(*) FROM asset_descriptions) AS described,
       (SELECT count(*) FROM assets a WHERE a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL) AS total;
