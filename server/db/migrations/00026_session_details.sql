-- +goose Up
-- Enough for someone to recognise their own devices and end the ones they do not.
ALTER TABLE sessions
    ADD COLUMN user_agent text NOT NULL DEFAULT '',
    ADD COLUMN ip text NOT NULL DEFAULT '',
    ADD COLUMN last_seen_at timestamptz NOT NULL DEFAULT now();

-- +goose Down
ALTER TABLE sessions
    DROP COLUMN last_seen_at,
    DROP COLUMN ip,
    DROP COLUMN user_agent;
