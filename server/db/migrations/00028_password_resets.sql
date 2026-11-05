-- +goose Up
CREATE TABLE password_resets (
    token_hash bytea PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    expires_at timestamptz NOT NULL
);
CREATE INDEX password_resets_user_idx ON password_resets (user_id);

-- +goose Down
DROP TABLE password_resets;
