-- +goose Up
-- What each person chose. Anything not chosen takes its default, so this can grow.
CREATE TABLE user_preferences (
    user_id uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    data jsonb NOT NULL DEFAULT '{}'
);

-- +goose Down
DROP TABLE user_preferences;
