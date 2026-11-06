-- +goose Up
-- Anyone can bring in their own Google Takeout or iCloud export by uploading its ZIP files. Such an
-- import waits in 'uploading' until every part is in.
ALTER TABLE imports DROP CONSTRAINT imports_status_check;
ALTER TABLE imports ADD CONSTRAINT imports_status_check
    CHECK (status IN ('uploading', 'running', 'done', 'failed', 'cancelled'));
ALTER TABLE imports
    ADD COLUMN from_zip boolean NOT NULL DEFAULT false,
    ADD COLUMN total integer NOT NULL DEFAULT 0,
    ADD COLUMN active_at timestamptz NOT NULL DEFAULT now();

-- The ZIP files of an import, kept only until it is done.
CREATE TABLE import_parts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    import_id uuid NOT NULL REFERENCES imports (id) ON DELETE CASCADE,
    name text NOT NULL,
    size_bytes bigint NOT NULL,
    path text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX import_parts_import ON import_parts (import_id);

-- Which files could not be brought in, and why, for the report.
CREATE TABLE import_problems (
    import_id uuid NOT NULL REFERENCES imports (id) ON DELETE CASCADE,
    name text NOT NULL,
    reason text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX import_problems_import ON import_problems (import_id);

-- The time zone an import worked out from where a photo was taken.
ALTER TABLE assets ADD COLUMN import_offset_minutes integer;

-- +goose Down
ALTER TABLE assets DROP COLUMN import_offset_minutes;
DROP TABLE import_problems;
DROP TABLE import_parts;
UPDATE imports SET status = 'cancelled', finished_at = now() WHERE status = 'uploading';
ALTER TABLE imports DROP COLUMN active_at, DROP COLUMN total, DROP COLUMN from_zip;
ALTER TABLE imports DROP CONSTRAINT imports_status_check;
ALTER TABLE imports ADD CONSTRAINT imports_status_check CHECK (status IN ('running', 'done', 'failed', 'cancelled'));
