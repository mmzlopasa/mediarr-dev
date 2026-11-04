-- +goose Up
CREATE TABLE webhooks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    url text NOT NULL,
    secret text NOT NULL,
    events text[] NOT NULL,
    last_status integer NOT NULL DEFAULT 0,
    last_error text NOT NULL DEFAULT '',
    last_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE webhooks;
