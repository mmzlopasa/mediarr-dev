-- +goose Up
-- An export of a whole library, for leaving Mediarr: ZIP parts built in the cache by a background job.
CREATE TABLE exports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Whose library is exported.
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- Who started it: the owner, or an administrator.
    created_by uuid REFERENCES users (id) ON DELETE SET NULL,
    status text NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'done', 'failed', 'cancelled', 'removed')),
    total_files integer NOT NULL DEFAULT 0,
    total_bytes bigint NOT NULL DEFAULT 0,
    done_files integer NOT NULL DEFAULT 0,
    done_bytes bigint NOT NULL DEFAULT 0,
    -- Files that were in the database but not on the disk.
    missing integer NOT NULL DEFAULT 0,
    -- Set once the list of files is made, so that a restart does not make it again.
    planned_at timestamptz,
    last_error text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,
    expires_at timestamptz
);
CREATE INDEX exports_user ON exports (user_id, created_at DESC);
CREATE UNIQUE INDEX exports_one_running ON exports (user_id) WHERE status = 'running';

-- The files of an export while it is made, each under the name it has in the ZIP files. part is set
-- once the part it is in is finished, so that a restart goes on with the rest.
CREATE TABLE export_files (
    export_id uuid NOT NULL REFERENCES exports (id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    -- Empty for a file in an external library, which is not copied.
    path text NOT NULL,
    part integer,
    sidecar boolean NOT NULL DEFAULT false,
    missing boolean NOT NULL DEFAULT false,
    PRIMARY KEY (export_id, asset_id)
);

CREATE TABLE export_parts (
    export_id uuid NOT NULL REFERENCES exports (id) ON DELETE CASCADE,
    number integer NOT NULL,
    size_bytes bigint NOT NULL,
    files integer NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (export_id, number)
);

-- +goose Down
DROP TABLE IF EXISTS export_parts;
DROP TABLE IF EXISTS export_files;
DROP TABLE IF EXISTS exports;
