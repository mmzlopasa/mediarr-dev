-- +goose Up
CREATE TABLE imports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    source text NOT NULL CHECK (source IN ('immich', 'takeout', 'icloud')),
    status text NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'done', 'failed', 'cancelled')),
    address text NOT NULL DEFAULT '',
    -- Kept only while the import runs.
    secret text NOT NULL DEFAULT '',
    folder text NOT NULL DEFAULT '',
    page integer NOT NULL DEFAULT 1,
    added integer NOT NULL DEFAULT 0,
    skipped integer NOT NULL DEFAULT 0,
    failed integer NOT NULL DEFAULT 0,
    last_error text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz
);

-- What came from where, so that importing again finds the same albums and people.
CREATE TABLE import_map (
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    origin text NOT NULL,
    kind text NOT NULL,
    remote_id text NOT NULL,
    local_id uuid NOT NULL,
    PRIMARY KEY (user_id, origin, kind, remote_id)
);

-- Whose face is where, from another system, as fractions of the picture. Analysis finds the face
-- itself, and this says who it is.
CREATE TABLE face_hints (
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    person_id uuid NOT NULL REFERENCES people (id) ON DELETE CASCADE,
    x1 real NOT NULL,
    y1 real NOT NULL,
    x2 real NOT NULL,
    y2 real NOT NULL,
    PRIMARY KEY (asset_id, person_id, x1, y1)
);

-- For files that do not say this themselves, as Takeout keeps it in a separate file.
ALTER TABLE assets
    ADD COLUMN import_taken_at timestamptz,
    ADD COLUMN import_latitude double precision,
    ADD COLUMN import_longitude double precision;

-- +goose Down
ALTER TABLE assets
    DROP COLUMN import_longitude,
    DROP COLUMN import_latitude,
    DROP COLUMN import_taken_at;
DROP TABLE face_hints;
DROP TABLE import_map;
DROP TABLE imports;
