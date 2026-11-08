-- +goose Up
-- A location taken away by hand stays away, even if the file has one.
ALTER TABLE assets ADD COLUMN manual_location_none boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE assets DROP COLUMN manual_location_none;
