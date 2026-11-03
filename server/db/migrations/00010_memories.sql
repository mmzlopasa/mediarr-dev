-- +goose Up
CREATE TABLE story_exports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title text NOT NULL,
    status text NOT NULL DEFAULT 'working' CHECK (status IN ('working', 'ready', 'failed')),
    path text,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX story_exports_user_idx ON story_exports (user_id, created_at DESC);

-- +goose Down
DROP TABLE story_exports;
