-- +goose Up
-- +goose StatementBegin
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- +goose StatementEnd
CREATE INDEX assets_name_trgm_idx ON assets USING gin (original_name gin_trgm_ops);

-- +goose Down
DROP INDEX assets_name_trgm_idx;
DROP EXTENSION IF EXISTS pg_trgm;
