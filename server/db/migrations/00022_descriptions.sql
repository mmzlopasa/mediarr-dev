-- +goose Up
CREATE TABLE asset_descriptions (
    asset_id uuid PRIMARY KEY REFERENCES assets (id) ON DELETE CASCADE,
    description text NOT NULL,
    model text NOT NULL,
    tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', description)) STORED,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX asset_descriptions_tsv_idx ON asset_descriptions USING gin (tsv);

-- +goose Down
DROP TABLE asset_descriptions;
