-- name: InsertAudit :exec
INSERT INTO audit_log (user_id, user_email, method, route, target, status, ip)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- name: ListAudit :many
SELECT * FROM audit_log
WHERE sqlc.narg('before')::bigint IS NULL OR id < sqlc.narg('before')
ORDER BY id DESC
LIMIT sqlc.arg('row_limit');

-- name: DeleteOldAudit :exec
DELETE FROM audit_log WHERE at < $1;
