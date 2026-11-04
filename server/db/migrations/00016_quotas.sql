-- +goose Up
ALTER TABLE users ADD COLUMN quota_bytes bigint;

-- +goose Down
ALTER TABLE users DROP COLUMN quota_bytes;
