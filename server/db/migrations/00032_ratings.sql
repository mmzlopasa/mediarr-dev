-- +goose Up
-- From 1 to 5 stars; 0 is none. A rating the owner gave is not replaced by one read from a file.
ALTER TABLE assets
    ADD COLUMN rating smallint NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    ADD COLUMN rating_by_owner boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE assets
    DROP COLUMN rating_by_owner,
    DROP COLUMN rating;
