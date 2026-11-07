-- +goose Up
-- An album can sit inside another. Deleting the one around it moves it to the top, never deletes it.
ALTER TABLE albums ADD COLUMN parent_id uuid REFERENCES albums (id) ON DELETE SET NULL,
    ADD CONSTRAINT albums_not_own_parent CHECK (parent_id IS NULL OR parent_id <> id);
CREATE INDEX albums_parent_idx ON albums (parent_id) WHERE parent_id IS NOT NULL;

-- +goose Down
ALTER TABLE albums DROP COLUMN parent_id;
