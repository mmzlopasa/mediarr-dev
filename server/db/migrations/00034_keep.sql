-- +goose Up
-- Other Mediarr servers whose encrypted backup this one keeps. A guest is invited with a code, and
-- after pairing only the hash of its secret is kept here.
CREATE TABLE keep_guests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL CHECK (length(name) BETWEEN 1 AND 100),
    status text NOT NULL DEFAULT 'invited' CHECK (status IN ('invited', 'active', 'stopped')),
    quota_bytes bigint NOT NULL CHECK (quota_bytes > 0),
    address text NOT NULL,
    invite_hash bytea UNIQUE,
    invite_expires_at timestamptz,
    secret_hash bytea,
    last_seen_at timestamptz,
    last_backup_at timestamptz,
    warned_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Where this server sends a copy of its backup besides the one in its settings: other Mediarr
-- servers that keep it.
CREATE TABLE backup_destinations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    address text NOT NULL,
    guest_id uuid NOT NULL,
    secret text NOT NULL,
    quota_bytes bigint NOT NULL DEFAULT 0,
    last_success_at timestamptz,
    last_error text NOT NULL DEFAULT '',
    warned_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- A run goes to the backup in the settings when it names no destination.
ALTER TABLE backup_runs ADD COLUMN destination_id uuid REFERENCES backup_destinations (id) ON DELETE CASCADE;

-- +goose Down
ALTER TABLE backup_runs DROP COLUMN destination_id;
DROP TABLE backup_destinations;
DROP TABLE keep_guests;
