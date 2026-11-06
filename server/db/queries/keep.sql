-- name: CreateKeepGuest :one
INSERT INTO keep_guests (name, quota_bytes, address, invite_hash, invite_expires_at)
VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: ListKeepGuests :many
SELECT * FROM keep_guests ORDER BY created_at;

-- name: GetKeepGuest :one
SELECT * FROM keep_guests WHERE id = $1;

-- name: SetKeepGuestInvite :one
-- A guest that has paired can get a new code too: a new server needs it to bring its backup back.
UPDATE keep_guests SET invite_hash = $2, invite_expires_at = $3 WHERE id = $1 RETURNING *;

-- name: PairKeepGuest :one
-- An invitation is used once, within its time.
-- Pairing again gives a new secret, and the old one stops working. A stopped guest stays stopped.
UPDATE keep_guests SET status = CASE WHEN status = 'stopped' THEN 'stopped' ELSE 'active' END, secret_hash = $2,
    invite_hash = NULL, invite_expires_at = NULL, last_seen_at = now()
WHERE invite_hash = $1 AND invite_expires_at > now() RETURNING *;

-- name: UpdateKeepGuest :one
UPDATE keep_guests SET quota_bytes = $2, status = $3 WHERE id = $1 RETURNING *;

-- name: DeleteKeepGuest :exec
DELETE FROM keep_guests WHERE id = $1;

-- name: SeenKeepGuest :exec
UPDATE keep_guests SET last_seen_at = now() WHERE id = $1;

-- name: KeepGuestBackedUp :exec
UPDATE keep_guests SET last_backup_at = now(), last_seen_at = now(), warned_at = NULL WHERE id = $1;

-- name: ListLateKeepGuests :many
-- Guests that have sent nothing for three days, not warned about in the last three.
SELECT * FROM keep_guests
WHERE status = 'active' AND coalesce(last_backup_at, created_at) < now() - interval '3 days'
    AND (warned_at IS NULL OR warned_at < now() - interval '3 days');

-- name: WarnedKeepGuest :exec
UPDATE keep_guests SET warned_at = now() WHERE id = $1;

-- name: CreateBackupDestination :one
INSERT INTO backup_destinations (name, address, guest_id, secret, quota_bytes) VALUES ($1, $2, $3, $4, $5) RETURNING *;

-- name: ListBackupDestinations :many
SELECT * FROM backup_destinations ORDER BY created_at;

-- name: GetBackupDestination :one
SELECT * FROM backup_destinations WHERE id = $1;

-- name: DeleteBackupDestination :exec
DELETE FROM backup_destinations WHERE id = $1;

-- name: FinishDestinationBackup :exec
UPDATE backup_destinations
SET last_success_at = CASE WHEN sqlc.arg('ok')::boolean THEN now() ELSE last_success_at END,
    warned_at = CASE WHEN sqlc.arg('ok')::boolean THEN NULL ELSE warned_at END,
    last_error = sqlc.arg('last_error')
WHERE id = sqlc.arg('id');

-- name: ListLateBackupDestinations :many
-- Copies that have not gone out for three days, not warned about in the last three.
SELECT * FROM backup_destinations
WHERE coalesce(last_success_at, created_at) < now() - interval '3 days'
    AND (warned_at IS NULL OR warned_at < now() - interval '3 days');

-- name: WarnedBackupDestination :exec
UPDATE backup_destinations SET warned_at = now() WHERE id = $1;
