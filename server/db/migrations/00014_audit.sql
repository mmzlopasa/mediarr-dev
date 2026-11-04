-- +goose Up
-- Who changed what. Never the content of a request, so no passwords or tokens can end up here.
CREATE TABLE audit_log (
    id bigserial PRIMARY KEY,
    at timestamptz NOT NULL DEFAULT now(),
    user_id uuid REFERENCES users (id) ON DELETE SET NULL,
    -- Kept when the account is deleted, because that is when the record matters most.
    user_email text NOT NULL DEFAULT '',
    method text NOT NULL,
    route text NOT NULL,
    target text NOT NULL DEFAULT '',
    status integer NOT NULL,
    ip text NOT NULL DEFAULT ''
);
CREATE INDEX audit_log_at_idx ON audit_log (at);

-- +goose Down
DROP TABLE audit_log;
