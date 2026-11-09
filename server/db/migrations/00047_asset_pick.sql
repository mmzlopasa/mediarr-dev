-- +goose Up
-- The verdict on a photo while going through a shoot: -1 rejected, 0 none, 1 picked.
ALTER TABLE assets ADD COLUMN pick smallint NOT NULL DEFAULT 0 CHECK (pick IN (-1, 0, 1));
CREATE INDEX assets_pick ON assets (user_id, pick) WHERE pick <> 0;

-- +goose Down
DROP INDEX IF EXISTS assets_pick;
ALTER TABLE assets DROP COLUMN IF EXISTS pick;
