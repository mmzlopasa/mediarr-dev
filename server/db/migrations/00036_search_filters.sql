-- +goose Up
-- Search can be narrowed to a rating and to a lens. Rated photos and lenses are few, so these
-- indexes stay small.
CREATE INDEX assets_rated_idx ON assets (user_id, rating) WHERE rating > 0;
CREATE INDEX exif_lens_idx ON exif (lower(lens)) WHERE lens IS NOT NULL;

-- +goose Down
DROP INDEX exif_lens_idx;
DROP INDEX assets_rated_idx;
