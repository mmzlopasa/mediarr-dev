-- name: CreateBackupRun :one
INSERT INTO backup_runs (kind) VALUES ($1) RETURNING id;

-- name: FinishBackupRun :exec
UPDATE backup_runs SET status = $2, message = $3, files = $4, finished_at = now() WHERE id = $1;

-- name: ListBackupRuns :many
SELECT * FROM backup_runs ORDER BY started_at DESC LIMIT 30;

-- name: LastSuccessfulBackup :one
SELECT coalesce(max(finished_at), '1970-01-01'::timestamptz)::timestamptz FROM backup_runs WHERE kind = 'backup' AND status = 'done';

-- name: ListUploadOriginals :many
SELECT a.original_path, a.checksum FROM assets a JOIN libraries l ON l.id = a.library_id WHERE l.kind = 'upload';
