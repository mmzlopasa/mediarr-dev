-- name: GetState :one
SELECT value FROM system_state WHERE key = $1;

-- name: SetState :exec
INSERT INTO system_state (key, value) VALUES ($1, $2)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now();
