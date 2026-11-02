-- +goose Up
CREATE TABLE system_state (
    key text PRIMARY KEY,
    value text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL UNIQUE CHECK (email = lower(email)),
    name text NOT NULL,
    password_hash text NOT NULL,
    is_admin boolean NOT NULL DEFAULT false,
    totp_secret text,
    totp_enabled boolean NOT NULL DEFAULT false,
    totp_last_step bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash bytea NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL
);
CREATE INDEX sessions_user_id_idx ON sessions (user_id);
CREATE INDEX sessions_expires_at_idx ON sessions (expires_at);

CREATE TABLE api_keys (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name text NOT NULL,
    key_hash bytea NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    last_used_at timestamptz
);
CREATE INDEX api_keys_user_id_idx ON api_keys (user_id);

CREATE TABLE libraries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name text NOT NULL,
    kind text NOT NULL CHECK (kind IN ('upload', 'external')),
    path text,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX libraries_one_upload_per_user_idx ON libraries (user_id) WHERE kind = 'upload';

CREATE TABLE assets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    library_id uuid NOT NULL REFERENCES libraries (id) ON DELETE RESTRICT,
    checksum bytea NOT NULL,
    original_name text NOT NULL,
    original_path text NOT NULL,
    size_bytes bigint NOT NULL,
    mime_type text,
    kind text NOT NULL DEFAULT 'unknown' CHECK (kind IN ('unknown', 'photo', 'video')),
    status text NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'ready', 'failed')),
    error text,
    width integer,
    height integer,
    blurhash text,
    -- UTC instant plus the original offset, so the timeline does not jump between time zones.
    taken_at timestamptz,
    taken_offset_minutes integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, checksum)
);
CREATE INDEX assets_user_created_idx ON assets (user_id, created_at DESC);
CREATE INDEX assets_user_taken_idx ON assets (user_id, taken_at DESC);
CREATE INDEX assets_user_status_idx ON assets (user_id, status);

CREATE TABLE asset_files (
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    kind text NOT NULL CHECK (kind IN ('thumb_small', 'thumb_large', 'sidecar')),
    path text NOT NULL,
    size_bytes bigint NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (asset_id, kind)
);

CREATE TABLE exif (
    asset_id uuid PRIMARY KEY REFERENCES assets (id) ON DELETE CASCADE,
    make text,
    model text,
    lens text,
    iso integer,
    f_number double precision,
    exposure_time text,
    focal_length double precision,
    latitude double precision,
    longitude double precision,
    raw jsonb NOT NULL
);

-- +goose Down
DROP TABLE exif;
DROP TABLE asset_files;
DROP TABLE assets;
DROP TABLE libraries;
DROP TABLE api_keys;
DROP TABLE sessions;
DROP TABLE users;
DROP TABLE system_state;
