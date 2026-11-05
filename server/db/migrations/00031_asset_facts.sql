-- +goose Up
-- What the owner said about a photo. It wins over the file, which is never changed.
ALTER TABLE assets
    ADD COLUMN manual_taken_at timestamptz,
    ADD COLUMN manual_offset_minutes integer,
    ADD COLUMN manual_latitude double precision,
    ADD COLUMN manual_longitude double precision,
    ADD COLUMN caption text NOT NULL DEFAULT '';

-- +goose Down
ALTER TABLE assets
    DROP COLUMN caption,
    DROP COLUMN manual_longitude,
    DROP COLUMN manual_latitude,
    DROP COLUMN manual_offset_minutes,
    DROP COLUMN manual_taken_at;
