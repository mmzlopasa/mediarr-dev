-- +goose Up
-- Recently added goes by when a photo reached the server.
CREATE INDEX assets_user_added_idx ON assets (user_id, created_at DESC)
    WHERE status = 'ready' AND live_photo_of IS NULL AND deleted_at IS NULL;

-- +goose Down
DROP INDEX assets_user_added_idx;
