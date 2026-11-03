-- +goose Up
-- GeoNames data (CC BY), loaded by the server on start. Nothing leaves the server to name a place.
CREATE TABLE places (
    name text NOT NULL,
    state text NOT NULL,
    country text NOT NULL,
    lat real NOT NULL,
    lon real NOT NULL
);
CREATE INDEX places_lat_idx ON places (lat);

ALTER TABLE exif
    ADD COLUMN city text,
    ADD COLUMN state text,
    ADD COLUMN country text,
    ADD COLUMN geocoded_at timestamptz;
CREATE INDEX exif_located_idx ON exif (asset_id) WHERE latitude IS NOT NULL;
CREATE INDEX exif_geocode_pending_idx ON exif (asset_id) WHERE latitude IS NOT NULL AND geocoded_at IS NULL;

-- +goose Down
DROP INDEX exif_geocode_pending_idx;
DROP INDEX exif_located_idx;
ALTER TABLE exif
    DROP COLUMN geocoded_at,
    DROP COLUMN country,
    DROP COLUMN state,
    DROP COLUMN city;
DROP TABLE places;
