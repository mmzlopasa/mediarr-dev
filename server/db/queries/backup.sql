-- name: CreateBackupRun :one
INSERT INTO backup_runs (kind, destination_id) VALUES ($1, $2) RETURNING id;

-- name: FinishBackupRun :exec
UPDATE backup_runs SET status = $2, message = $3, files = $4, finished_at = now() WHERE id = $1;

-- name: ListBackupRuns :many
SELECT r.*, d.name AS destination_name FROM backup_runs r LEFT JOIN backup_destinations d ON d.id = r.destination_id
ORDER BY r.started_at DESC LIMIT 30;

-- name: GetBackupRun :one
SELECT * FROM backup_runs WHERE id = $1;

-- name: LastSuccessfulBackup :one
SELECT coalesce(max(finished_at), '1970-01-01'::timestamptz)::timestamptz FROM backup_runs WHERE kind = 'backup' AND status = 'done';

-- name: ListUploadOriginals :many
SELECT a.original_path, a.checksum FROM assets a JOIN libraries l ON l.id = a.library_id WHERE l.kind = 'upload';
