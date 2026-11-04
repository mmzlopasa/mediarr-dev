-- +goose Up
-- Immich lists each file's SHA-1, so an import can skip what is here without downloading it.
ALTER TABLE assets ADD COLUMN checksum_sha1 bytea;
CREATE INDEX assets_user_sha1_idx ON assets (user_id, checksum_sha1) WHERE checksum_sha1 IS NOT NULL;

-- +goose Down
DROP INDEX assets_user_sha1_idx;
ALTER TABLE assets DROP COLUMN checksum_sha1;
