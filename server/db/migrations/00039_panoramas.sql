-- +goose Up
-- How a photo is meant to be seen: equirectangular is a 360° panorama. Photos already here are
-- found from the metadata kept when they came in.
ALTER TABLE assets ADD COLUMN projection text;
UPDATE assets a SET projection = lower(e.raw ->> 'ProjectionType')
FROM exif e
WHERE e.asset_id = a.id AND e.raw ? 'ProjectionType' AND lower(e.raw ->> 'ProjectionType') = 'equirectangular';

-- +goose Down
ALTER TABLE assets DROP COLUMN projection;
