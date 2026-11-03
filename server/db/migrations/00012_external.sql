-- +goose Up
ALTER TABLE assets ADD COLUMN missing_at timestamptz;
ALTER TABLE libraries
    ADD COLUMN scan_started_at timestamptz,
    ADD COLUMN scan_finished_at timestamptz,
    ADD COLUMN scan_error text;
CREATE UNIQUE INDEX libraries_one_external_idx ON libraries ((true)) WHERE kind = 'external';
CREATE INDEX assets_library_path_idx ON assets (library_id, original_path);

-- Every file seen in an external library, also those that got no record of their own because the
-- user already has the same content. A rescan reads only what changed since.
CREATE TABLE external_files (
    library_id uuid NOT NULL REFERENCES libraries (id) ON DELETE CASCADE,
    path text NOT NULL,
    size_bytes bigint NOT NULL,
    mtime timestamptz NOT NULL,
    PRIMARY KEY (library_id, path)
);

-- +goose Down
DROP TABLE external_files;
DROP INDEX assets_library_path_idx;
DROP INDEX libraries_one_external_idx;
ALTER TABLE libraries
    DROP COLUMN scan_error,
    DROP COLUMN scan_finished_at,
    DROP COLUMN scan_started_at;
ALTER TABLE assets DROP COLUMN missing_at;
