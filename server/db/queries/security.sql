-- name: InsertSecurityEvent :exec
INSERT INTO security_events (kind, email, ip, user_agent, detail) VALUES ($1, $2, $3, $4, $5);

-- name: ListSecurityEvents :many
SELECT * FROM security_events
WHERE sqlc.narg('before')::bigint IS NULL OR id < sqlc.narg('before')
ORDER BY id DESC
LIMIT sqlc.arg('row_limit');

-- name: DeleteOldSecurityEvents :exec
DELETE FROM security_events WHERE at < $1;

-- name: SeeDevice :one
INSERT INTO trusted_devices (token_hash, email, ip, user_agent) VALUES ($1, $2, $3, $4)
ON CONFLICT (token_hash) DO UPDATE
SET email = EXCLUDED.email, ip = EXCLUDED.ip, user_agent = EXCLUDED.user_agent, last_seen = now()
RETURNING *;

-- name: ApproveDeviceByToken :exec
UPDATE trusted_devices SET approved_at = COALESCE(approved_at, now()) WHERE token_hash = $1;

-- name: ListDevices :many
SELECT * FROM trusted_devices ORDER BY approved_at IS NOT NULL, last_seen DESC LIMIT 500;

-- name: ApproveDevice :execrows
UPDATE trusted_devices SET approved_at = now() WHERE id = $1;

-- name: DeleteDevice :execrows
DELETE FROM trusted_devices WHERE id = $1;
