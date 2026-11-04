-- +goose Up
CREATE TABLE family_members (
    user_id uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    added_at timestamptz NOT NULL DEFAULT now()
);
-- What a member shares with the family is a smart album of theirs, seen by all the others. So the
-- rules, the rights and the vault work as they do for any shared album.
ALTER TABLE albums ADD COLUMN is_family boolean NOT NULL DEFAULT false;
CREATE INDEX albums_family_idx ON albums (owner_id) WHERE is_family;

-- +goose Down
DROP INDEX albums_family_idx;
DELETE FROM albums WHERE is_family;
ALTER TABLE albums DROP COLUMN is_family;
DROP TABLE family_members;
