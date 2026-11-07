-- +goose Up
-- Each phone that backs up says how it is doing. The server keeps the checksums it says are safe,
-- and counts from its own assets which of them really are.
CREATE TABLE backup_devices (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name text NOT NULL DEFAULT '',
    platform text NOT NULL DEFAULT '',
    app_version text NOT NULL DEFAULT '',
    pending integer NOT NULL DEFAULT 0,
    working integer NOT NULL DEFAULT 0,
    verified integer NOT NULL DEFAULT 0,
    failed integer NOT NULL DEFAULT 0,
    -- What could not be sent, as the phone names it: [{name, reason}].
    failures jsonb NOT NULL DEFAULT '[]',
    created_at timestamptz NOT NULL DEFAULT now(),
    reported_at timestamptz NOT NULL DEFAULT now(),
    -- When the owner was told it went quiet; cleared when it reports again.
    quiet_told_at timestamptz
);
CREATE INDEX backup_devices_user_idx ON backup_devices (user_id);
CREATE INDEX backup_devices_reported_idx ON backup_devices (reported_at) WHERE quiet_told_at IS NULL;

CREATE TABLE backup_device_files (
    device_id uuid NOT NULL REFERENCES backup_devices (id) ON DELETE CASCADE,
    checksum bytea NOT NULL,
    PRIMARY KEY (device_id, checksum)
);

-- Days without a report before a device counts as quiet; 0 never warns.
ALTER TABLE users ADD COLUMN backup_quiet_days integer NOT NULL DEFAULT 3;

-- +goose Down
ALTER TABLE users DROP COLUMN backup_quiet_days;
DROP TABLE backup_device_files;
DROP TABLE backup_devices;
