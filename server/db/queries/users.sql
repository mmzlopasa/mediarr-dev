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
DELETE FROM sessions WHERE user_id = sqlc.arg('user_id') AND token_hash IS DISTINCT FROM sqlc.arg('keep');

-- name: DeleteUserAPIKeys :exec
DELETE FROM api_keys WHERE user_id = $1;

-- name: DeleteExpiredSessions :exec
DELETE FROM sessions WHERE expires_at <= now();

-- name: CreateAPIKey :one
INSERT INTO api_keys (user_id, name, key_hash, scopes, expires_at) VALUES ($1, $2, $3, $4, $5) RETURNING id;

-- name: ListAPIKeys :many
SELECT id, name, scopes, created_at, last_used_at, expires_at FROM api_keys WHERE user_id = $1 ORDER BY created_at DESC;

-- name: GetUserByAPIKey :one
UPDATE api_keys k SET last_used_at = now() FROM users u
WHERE k.key_hash = $1 AND u.id = k.user_id AND (k.expires_at IS NULL OR k.expires_at > now())
RETURNING sqlc.embed(u), k.scopes;

-- name: DeleteAPIKey :exec
DELETE FROM api_keys WHERE id = $1 AND user_id = $2;

-- name: SetUserQuota :execrows
UPDATE users SET quota_bytes = $2 WHERE id = $1;

-- name: UserStoredBytes :one
-- Only what lives in Mediarr's own storage: an external folder is on the user's disk already.
SELECT coalesce(sum(a.size_bytes), 0)::bigint
FROM assets a JOIN libraries l ON l.id = a.library_id
WHERE a.user_id = $1 AND l.kind = 'upload';

-- name: ListUserStorage :many
SELECT u.id, u.name, u.email, u.quota_bytes,
       coalesce(sum(a.size_bytes) FILTER (WHERE l.kind = 'upload'), 0)::bigint AS stored_bytes,
       count(a.id) AS assets
FROM users u
LEFT JOIN assets a ON a.user_id = u.id
LEFT JOIN libraries l ON l.id = a.library_id
GROUP BY u.id
ORDER BY stored_bytes DESC, u.email;

-- name: CreatePasskey :one
INSERT INTO passkeys (user_id, credential_id, name, credential) VALUES ($1, $2, $3, $4) RETURNING id;

-- name: ListPasskeys :many
SELECT id, user_id, credential_id, name, credential, created_at, last_used_at FROM passkeys WHERE user_id = $1 ORDER BY created_at;

-- name: UpdatePasskeyCredential :exec
UPDATE passkeys SET credential = $2, last_used_at = now() WHERE credential_id = $1;

-- name: DeletePasskey :exec
DELETE FROM passkeys WHERE id = $1 AND user_id = $2;
