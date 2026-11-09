-- +goose Up
-- The same video saved twice is proposed as a duplicate: four frames of each are compared. An empty
-- array is a video that could not be read, so it is not tried again and again.
ALTER TABLE assets ADD COLUMN vhash bigint[];
CREATE INDEX assets_unfingerprinted_videos ON assets (id)
    WHERE kind = 'video' AND vhash IS NULL AND status = 'ready' AND deleted_at IS NULL;

-- +goose Down
DROP INDEX IF EXISTS assets_unfingerprinted_videos;
ALTER TABLE assets DROP COLUMN IF EXISTS vhash;
