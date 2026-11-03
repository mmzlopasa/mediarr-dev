-- +goose Up
ALTER TABLE assets
    ADD COLUMN content_id text,
    ADD COLUMN live_photo_of uuid REFERENCES assets (id) ON DELETE SET NULL,
    ADD COLUMN duration_ms bigint,
    ADD COLUMN video_codec text,
    ADD COLUMN sprite_columns integer,
    ADD COLUMN sprite_rows integer,
    ADD COLUMN sprite_count integer,
    ADD COLUMN sprite_interval_ms integer;

CREATE INDEX assets_content_id_idx ON assets (user_id, content_id) WHERE content_id IS NOT NULL;
CREATE INDEX assets_live_photo_of_idx ON assets (live_photo_of) WHERE live_photo_of IS NOT NULL;

DROP INDEX assets_timeline_idx;
CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND live_photo_of IS NULL;

ALTER TABLE asset_files DROP CONSTRAINT asset_files_kind_check;
ALTER TABLE asset_files ADD CONSTRAINT asset_files_kind_check
    CHECK (kind IN ('thumb_small', 'thumb_large', 'thumb_full', 'sidecar', 'hls', 'sprite', 'motion_video'));

-- +goose Down
DELETE FROM asset_files WHERE kind IN ('thumb_full', 'hls', 'sprite', 'motion_video');
ALTER TABLE asset_files DROP CONSTRAINT asset_files_kind_check;
ALTER TABLE asset_files ADD CONSTRAINT asset_files_kind_check
    CHECK (kind IN ('thumb_small', 'thumb_large', 'sidecar'));

DROP INDEX assets_timeline_idx;
CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL;
DROP INDEX assets_live_photo_of_idx;
DROP INDEX assets_content_id_idx;

ALTER TABLE assets
    DROP COLUMN sprite_interval_ms,
    DROP COLUMN sprite_count,
    DROP COLUMN sprite_rows,
    DROP COLUMN sprite_columns,
    DROP COLUMN video_codec,
    DROP COLUMN duration_ms,
    DROP COLUMN live_photo_of,
    DROP COLUMN content_id;
