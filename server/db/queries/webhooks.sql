-- name: CreateWebhook :one
INSERT INTO webhooks (url, secret, events) VALUES ($1, $2, $3) RETURNING id;

-- name: ListWebhooks :many
SELECT * FROM webhooks ORDER BY created_at DESC;

-- name: GetWebhook :one
SELECT * FROM webhooks WHERE id = $1;

-- name: DeleteWebhook :exec
DELETE FROM webhooks WHERE id = $1;

-- name: WebhooksForEvent :many
SELECT id FROM webhooks WHERE sqlc.arg('event')::text = ANY(events);

-- name: RecordWebhookDelivery :exec
UPDATE webhooks SET last_status = $2, last_error = $3, last_at = now() WHERE id = $1;
