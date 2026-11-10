-- +goose Up
-- A TV showing photos sent from the web or the app. The TV gets an address with this token, which
-- opens only the assets added here, and only until it expires or casting stops.
CREATE TABLE cast_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- Only the hash is kept, as for sessions and links.
    token_hash bytea NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL
);
CREATE INDEX cast_sessions_user ON cast_sessions (user_id);
CREATE INDEX cast_sessions_expiry ON cast_sessions (expires_at);

CREATE TABLE cast_session_assets (
    session_id uuid NOT NULL REFERENCES cast_sessions (id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    PRIMARY KEY (session_id, asset_id)
);

-- +goose Down
DROP TABLE IF EXISTS cast_session_assets;
DROP TABLE IF EXISTS cast_sessions;
