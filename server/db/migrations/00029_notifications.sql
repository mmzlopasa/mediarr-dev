-- +goose Up
CREATE TABLE notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    kind text NOT NULL,
    subject text NOT NULL DEFAULT '',
    ref text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),
    read_at timestamptz
);
CREATE INDEX notifications_user_idx ON notifications (user_id, created_at DESC);

-- +goose Down
DROP TABLE notifications;
