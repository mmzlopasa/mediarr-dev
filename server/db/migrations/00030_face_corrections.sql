-- +goose Up
ALTER TABLE people ADD COLUMN birth_date date;

-- A box someone said is not a person. Analysing the picture again must not bring it back.
CREATE TABLE face_ignored (
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    x1 real NOT NULL,
    y1 real NOT NULL,
    x2 real NOT NULL,
    y2 real NOT NULL,
    PRIMARY KEY (asset_id, x1, y1)
);

-- +goose Down
DROP TABLE face_ignored;
ALTER TABLE people DROP COLUMN birth_date;
