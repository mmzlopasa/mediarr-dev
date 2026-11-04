-- +goose Up
CREATE TABLE backup_runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kind text NOT NULL CHECK (kind IN ('backup', 'restore_test')),
    status text NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'done', 'failed')),
    message text NOT NULL DEFAULT '',
    files bigint NOT NULL DEFAULT 0,
    started_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz
);
CREATE INDEX backup_runs_started_idx ON backup_runs (started_at DESC);

-- +goose Down
DROP TABLE backup_runs;
