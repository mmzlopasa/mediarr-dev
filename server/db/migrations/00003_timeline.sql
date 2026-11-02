-- +goose Up
ALTER TABLE assets
    ADD COLUMN is_favorite boolean NOT NULL DEFAULT false,
    ADD COLUMN archived_at timestamptz,
    ADD COLUMN deleted_at timestamptz,
    ADD COLUMN aspect_ratio real,
    -- Local capture time, so days and months match where the photo was taken. Falls back to upload time.
    ADD COLUMN local_at timestamp GENERATED ALWAYS AS (
        (COALESCE(taken_at, created_at) AT TIME ZONE 'UTC') + make_interval(mins => COALESCE(taken_offset_minutes, 0))
    ) STORED;

CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL;

-- +goose Down
DROP INDEX assets_timeline_idx;
ALTER TABLE assets
    DROP COLUMN local_at,
    DROP COLUMN aspect_ratio,
    DROP COLUMN deleted_at,
    DROP COLUMN archived_at,
    DROP COLUMN is_favorite;
