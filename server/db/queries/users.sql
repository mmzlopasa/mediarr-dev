-- name: CountUsers :one
SELECT count(*) FROM users;

-- name: LockSetup :exec
SELECT pg_advisory_xact_lock(727001);

-- name: CreateUser :one
INSERT INTO users (email, name, password_hash, is_admin) VALUES ($1, $2, $3, $4) RETURNING *;

-- name: UpsertUser :one
INSERT INTO users (email, name, password_hash, is_admin) VALUES ($1, $2, $3, $4)
ON CONFLICT (email) DO UPDATE
SET name = EXCLUDED.name, password_hash = EXCLUDED.password_hash, is_admin = EXCLUDED.is_admin,
    totp_enabled = false, totp_secret = NULL, updated_at = now()
RETURNING *;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1;

-- name: GetUser :one
SELECT * FROM users WHERE id = $1;

-- name: ListUsers :many
SELECT * FROM users ORDER BY created_at;

-- name: SetPassword :exec
UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1;

-- name: SetTotpSecret :exec
UPDATE users SET totp_secret = $2, totp_enabled = false, updated_at = now() WHERE id = $1;

-- name: EnableTotp :exec
UPDATE users SET totp_enabled = true, totp_last_step = $2, updated_at = now() WHERE id = $1;

-- name: DisableTotp :exec
UPDATE users SET totp_enabled = false, totp_secret = NULL, updated_at = now() WHERE id = $1;

-- name: ClaimTotpStep :execrows
UPDATE users SET totp_last_step = $2 WHERE id = $1 AND totp_last_step < $2;

-- name: CreateSession :exec
INSERT INTO sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3);

-- name: GetUserBySessionToken :one
SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id
WHERE s.token_hash = $1 AND s.expires_at > now();

-- name: DeleteSession :exec
DELETE FROM sessions WHERE token_hash = $1;

-- name: DeleteOtherSessions :exec
DELETE FROM sessions WHERE user_id = $1 AND token_hash <> $2;

-- name: DeleteExpiredSessions :exec
DELETE FROM sessions WHERE expires_at <= now();

-- name: CreateAPIKey :one
INSERT INTO api_keys (user_id, name, key_hash) VALUES ($1, $2, $3) RETURNING id;

-- name: GetUserByAPIKey :one
UPDATE api_keys k SET last_used_at = now() FROM users u
WHERE k.key_hash = $1 AND u.id = k.user_id
RETURNING u.*;
