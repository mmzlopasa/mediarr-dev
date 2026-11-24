-- +goose Up
-- Organizing reads the photos it has not seen yet in order of when they were taken, a page at a
-- time. With the time in the index a page no longer sorts every waiting photo.
DROP INDEX assets_unorganized_idx;
CREATE INDEX assets_unorganized_idx ON assets (user_id, local_at)
    WHERE organized_at IS NULL AND kind = 'photo' AND status = 'ready' AND deleted_at IS NULL
      AND archived_at IS NULL AND vault_at IS NULL AND live_photo_of IS NULL;

-- Cleanup tells how many photos still wait for their sharpness to be measured.
CREATE INDEX assets_unmeasured_photos ON assets (user_id)
    WHERE kind = 'photo' AND status = 'ready' AND deleted_at IS NULL AND sharpness IS NULL;

-- Naming a place looks in a box around it, so both sides of the box come from the index.
DROP INDEX places_lat_idx;
CREATE INDEX places_lat_lon_idx ON places (lat, lon);

-- +goose Down
DROP INDEX places_lat_lon_idx;
CREATE INDEX places_lat_idx ON places (lat);
DROP INDEX assets_unmeasured_photos;
DROP INDEX assets_unorganized_idx;
CREATE INDEX assets_unorganized_idx ON assets (user_id) WHERE organized_at IS NULL AND kind = 'photo' AND status = 'ready';
