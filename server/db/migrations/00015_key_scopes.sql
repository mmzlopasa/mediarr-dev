-- +goose Up
ALTER TABLE api_keys
    ADD COLUMN scopes text[] NOT NULL DEFAULT '{}',
    ADD COLUMN expires_at timestamptz;
-- Until now only phones had keys, and a phone's key only ever sends files.
UPDATE api_keys SET scopes = '{upload}';

-- +goose Down
ALTER TABLE api_keys
    DROP COLUMN expires_at,
    DROP COLUMN scopes;
