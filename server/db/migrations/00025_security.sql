-- +goose Up
-- Who tried to get in, whether or not it worked.
CREATE TABLE security_events (
    id bigserial PRIMARY KEY,
    at timestamptz NOT NULL DEFAULT now(),
    kind text NOT NULL,
    email text NOT NULL DEFAULT '',
    ip text NOT NULL DEFAULT '',
    user_agent text NOT NULL DEFAULT '',
    detail text NOT NULL DEFAULT ''
);
CREATE INDEX security_events_at_idx ON security_events (at);

-- Browsers and phones that have tried to sign in. Only an approved one may, when that is turned on.
CREATE TABLE trusted_devices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash bytea NOT NULL UNIQUE,
    email text NOT NULL DEFAULT '',
    ip text NOT NULL DEFAULT '',
    user_agent text NOT NULL DEFAULT '',
    first_seen timestamptz NOT NULL DEFAULT now(),
    last_seen timestamptz NOT NULL DEFAULT now(),
    approved_at timestamptz
);

-- +goose Down
DROP TABLE trusted_devices;
DROP TABLE security_events;
