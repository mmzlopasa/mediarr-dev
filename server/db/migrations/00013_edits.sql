-- +goose Up
-- Originals stay as they are: this is the list of changes, applied only to the previews.
ALTER TABLE assets
    ADD COLUMN edits jsonb,
    ADD COLUMN edit_revision integer NOT NULL DEFAULT 0,
    ADD COLUMN edit_applied integer NOT NULL DEFAULT 0;

ALTER TABLE asset_files DROP CONSTRAINT asset_files_kind_check;
ALTER TABLE asset_files ADD CONSTRAINT asset_files_kind_check
    CHECK (kind IN ('thumb_small', 'thumb_large', 'thumb_full', 'thumb_source', 'sidecar', 'hls', 'sprite', 'motion_video'));

-- +goose Down
DELETE FROM asset_files WHERE kind = 'thumb_source';
ALTER TABLE asset_files DROP CONSTRAINT asset_files_kind_check;
ALTER TABLE asset_files ADD CONSTRAINT asset_files_kind_check
    CHECK (kind IN ('thumb_small', 'thumb_large', 'thumb_full', 'sidecar', 'hls', 'sprite', 'motion_video'));
ALTER TABLE assets
    DROP COLUMN edit_applied,
    DROP COLUMN edit_revision,
    DROP COLUMN edits;
