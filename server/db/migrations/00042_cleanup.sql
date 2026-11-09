-- +goose Up
-- What the owner chose to keep in Clean up is not offered there again.
ALTER TABLE assets ADD COLUMN cleanup_kept_at timestamptz;
CREATE INDEX assets_large_videos ON assets (user_id, size_bytes DESC)
    WHERE kind = 'video' AND deleted_at IS NULL;
CREATE INDEX assets_sharpness ON assets (user_id, sharpness)
    WHERE kind = 'photo' AND deleted_at IS NULL AND sharpness IS NOT NULL;

-- +goose Down
DROP INDEX IF EXISTS assets_sharpness;
DROP INDEX IF EXISTS assets_large_videos;
ALTER TABLE assets DROP COLUMN IF EXISTS cleanup_kept_at;
