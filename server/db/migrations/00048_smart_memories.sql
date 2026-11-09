-- +goose Up
-- Memories worked out once a day, so the page only reads a few rows, and what the owner hid.
CREATE TABLE memories (
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    kind text NOT NULL,
    key text NOT NULL,
    title text NOT NULL DEFAULT '',
    title_params jsonb NOT NULL DEFAULT '{}',
    items uuid[] NOT NULL DEFAULT '{}',
    rank integer NOT NULL DEFAULT 0,
    shown_from date,
    shown_until date,
    hidden_at timestamptz,
    PRIMARY KEY (user_id, kind, key)
);
CREATE INDEX memories_shown ON memories (user_id, shown_from, shown_until) WHERE hidden_at IS NULL;

CREATE TABLE memory_hidden_people (
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    person_id uuid NOT NULL REFERENCES people (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, person_id)
);

-- For which day the memories of an account were last worked out.
CREATE TABLE memory_runs (
    user_id uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    computed_for date NOT NULL
);

-- "On this day" looks at the month and day of every photo; with 100k photos this keeps it quick.
CREATE INDEX assets_on_this_day ON assets (user_id, (EXTRACT(MONTH FROM local_at)), (EXTRACT(DAY FROM local_at)))
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND vault_at IS NULL
      AND live_photo_of IS NULL AND stack_parent IS NULL;

-- +goose Down
DROP INDEX IF EXISTS assets_on_this_day;
DROP TABLE IF EXISTS memory_runs;
DROP TABLE IF EXISTS memory_hidden_people;
DROP TABLE IF EXISTS memories;
