-- +goose Up
-- Who signed in through a provider stays tied to that identity, whatever email it later reports.
CREATE TABLE oidc_identities (
    issuer text NOT NULL,
    subject text NOT NULL,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (issuer, subject)
);
CREATE INDEX oidc_identities_user_idx ON oidc_identities (user_id);

-- +goose Down
DROP TABLE oidc_identities;
