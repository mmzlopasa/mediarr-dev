-- +goose Up
-- A picture of the person, kept as a small square file. The version changes with each new picture,
-- so a cached old one is not shown, and zero means there is none.
ALTER TABLE users ADD COLUMN avatar_version integer NOT NULL DEFAULT 0;

-- +goose Down
ALTER TABLE users DROP COLUMN avatar_version;
