-- name: ReportBackupDevice :one
-- A device of another user with the same id is never taken over: the row stays theirs and nothing
-- is returned.
INSERT INTO backup_devices (id, user_id, name, platform, app_version, pending, working, verified, failed, failures)
VALUES (@id, @user_id, @name, @platform, @app_version, @pending, @working, @verified, @failed, @failures)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name, platform = EXCLUDED.platform, app_version = EXCLUDED.app_version,
    pending = EXCLUDED.pending, working = EXCLUDED.working, verified = EXCLUDED.verified,
    failed = EXCLUDED.failed,
    failures = CASE WHEN @keep_failures::boolean THEN backup_devices.failures ELSE EXCLUDED.failures END,
    reported_at = now(), quiet_told_at = NULL
WHERE backup_devices.user_id = EXCLUDED.user_id
RETURNING id;

-- name: ClearBackupDeviceFiles :exec
DELETE FROM backup_device_files WHERE device_id = $1;

-- name: AddBackupDeviceFiles :exec
INSERT INTO backup_device_files (device_id, checksum)
SELECT @device_id, unnest(@checksums::bytea[])
ON CONFLICT DO NOTHING;

-- name: ListBackupDevices :many
-- The server's own count: a file is safe only while an asset of the owner has its checksum and is
-- not in the trash.
SELECT d.*,
       (SELECT count(*) FROM backup_device_files f WHERE f.device_id = d.id)::bigint AS files,
       (SELECT count(*) FROM backup_device_files f
          JOIN assets a ON a.user_id = d.user_id AND a.checksum = f.checksum AND a.deleted_at IS NULL
         WHERE f.device_id = d.id)::bigint AS confirmed,
       (SELECT count(*) FROM backup_device_files f
          JOIN assets a ON a.user_id = d.user_id AND a.checksum = f.checksum AND a.deleted_at IS NOT NULL
         WHERE f.device_id = d.id)::bigint AS trashed,
       u.email AS owner_email, u.name AS owner_name, u.backup_quiet_days AS quiet_days
FROM backup_devices d
JOIN users u ON u.id = d.user_id
WHERE (@all_users::boolean OR d.user_id = @user_id)
ORDER BY d.reported_at DESC
LIMIT 500;

-- name: GetBackupDevice :one
SELECT * FROM backup_devices WHERE id = $1 AND user_id = $2;

-- name: MissingBackupDeviceFiles :many
-- Files the device says it sent that are not safe on the server: in the trash (with its name) or
-- gone altogether.
SELECT f.checksum, coalesce(a.original_name, '')::text AS name, (a.id IS NOT NULL)::boolean AS in_trash
FROM backup_device_files f
JOIN backup_devices d ON d.id = f.device_id
LEFT JOIN assets a ON a.user_id = d.user_id AND a.checksum = f.checksum
WHERE f.device_id = @device_id AND (a.id IS NULL OR a.deleted_at IS NOT NULL)
ORDER BY f.checksum
LIMIT 500;

-- name: DeleteBackupDevice :execrows
DELETE FROM backup_devices WHERE id = $1 AND user_id = $2;

-- name: SetBackupQuietDays :exec
UPDATE users SET backup_quiet_days = $2 WHERE id = $1;

-- name: GetBackupQuietDays :one
SELECT backup_quiet_days FROM users WHERE id = $1;

-- name: QuietBackupDevices :many
-- Devices past their owner's threshold that nobody was told about yet.
SELECT d.id, d.user_id, d.name, d.reported_at, u.email, u.name AS owner_name, u.language
FROM backup_devices d
JOIN users u ON u.id = d.user_id
WHERE d.quiet_told_at IS NULL AND u.backup_quiet_days > 0
  AND d.reported_at < now() - make_interval(days => u.backup_quiet_days)
LIMIT 1000;

-- name: MarkBackupDeviceQuietTold :exec
UPDATE backup_devices SET quiet_told_at = now() WHERE id = $1;
