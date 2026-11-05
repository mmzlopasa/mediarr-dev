-- name: CreateNotification :exec
INSERT INTO notifications (user_id, kind, subject, ref) VALUES ($1, $2, $3, $4);

-- name: NotifyAdmins :exec
INSERT INTO notifications (user_id, kind, subject, ref)
SELECT id, $1, $2, $3 FROM users WHERE is_admin;

-- name: ListNotifications :many
SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC, id LIMIT $2;

-- name: CountUnreadNotifications :one
SELECT count(*) FROM notifications WHERE user_id = $1 AND read_at IS NULL;

-- name: MarkNotificationsRead :exec
UPDATE notifications SET read_at = now() WHERE user_id = $1 AND read_at IS NULL;

-- name: DeleteNotification :execrows
DELETE FROM notifications WHERE id = $1 AND user_id = $2;

-- name: DeleteOldNotifications :exec
DELETE FROM notifications WHERE created_at < now() - interval '90 days';
