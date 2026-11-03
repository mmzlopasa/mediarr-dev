-- +goose Up
ALTER TABLE assets ADD COLUMN vault_at timestamptz;
ALTER TABLE users ADD COLUMN vault_pin_hash text;

DROP INDEX assets_timeline_idx;
CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND vault_at IS NULL AND live_photo_of IS NULL;
CREATE INDEX assets_trash_idx ON assets (deleted_at) WHERE deleted_at IS NOT NULL;

CREATE TABLE vault_sessions (
    token_hash bytea PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    expires_at timestamptz NOT NULL
);

CREATE TABLE tags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name text NOT NULL CHECK (length(name) BETWEEN 1 AND 100),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX tags_user_name_idx ON tags (user_id, lower(name));

CREATE TABLE asset_tags (
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    tag_id uuid NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (asset_id, tag_id)
);
CREATE INDEX asset_tags_tag_idx ON asset_tags (tag_id);

-- A photo in the vault is out of reach everywhere. Only the vault's own endpoints read it.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION album_item_ids(p_album uuid) RETURNS SETOF uuid LANGUAGE sql STABLE AS $$
    SELECT a.id
    FROM album_assets aa
    JOIN albums al ON al.id = aa.album_id AND al.rules IS NULL
    JOIN assets a ON a.id = aa.asset_id
    WHERE aa.album_id = p_album AND a.status = 'ready' AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
    UNION ALL
    SELECT a.id
    FROM albums al
    JOIN assets a ON a.user_id = al.owner_id
    LEFT JOIN exif e ON e.asset_id = a.id
    WHERE al.id = p_album AND al.rules IS NOT NULL
      AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
      AND album_rules_match(al.rules, a.id, a.kind, a.local_at, e.make, e.model)
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION album_has_asset(p_album uuid, p_asset uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1
        FROM assets asked
        JOIN assets a ON a.id = COALESCE(asked.live_photo_of, asked.id)
        JOIN albums al ON al.id = p_album
        LEFT JOIN exif e ON e.asset_id = a.id
        WHERE asked.id = p_asset AND asked.deleted_at IS NULL AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.status = 'ready'
          AND CASE WHEN al.rules IS NULL
                THEN EXISTS (SELECT 1 FROM album_assets aa WHERE aa.album_id = p_album AND aa.asset_id = a.id)
                ELSE a.user_id = al.owner_id AND a.archived_at IS NULL
                     AND album_rules_match(al.rules, a.id, a.kind, a.local_at, e.make, e.model)
              END
    )
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION asset_visible_to(p_asset uuid, p_user uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM assets a
        WHERE a.id = p_asset AND a.deleted_at IS NULL AND a.vault_at IS NULL AND (
            a.user_id = p_user
            OR (a.archived_at IS NULL AND EXISTS (
                SELECT 1 FROM partner_shares ps
                WHERE ps.owner_id = a.user_id AND ps.partner_id = p_user
                  AND (ps.since_at IS NULL OR a.local_at >= ps.since_at)))
            OR EXISTS (
                SELECT 1 FROM albums al
                WHERE (al.owner_id = p_user OR EXISTS (
                        SELECT 1 FROM album_members m WHERE m.album_id = al.id AND m.user_id = p_user))
                  AND album_has_asset(al.id, p_asset))
        )
    )
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION album_item_ids(p_album uuid) RETURNS SETOF uuid LANGUAGE sql STABLE AS $$
    SELECT a.id
    FROM album_assets aa
    JOIN albums al ON al.id = aa.album_id AND al.rules IS NULL
    JOIN assets a ON a.id = aa.asset_id
    WHERE aa.album_id = p_album AND a.status = 'ready' AND a.deleted_at IS NULL AND a.live_photo_of IS NULL
    UNION ALL
    SELECT a.id
    FROM albums al
    JOIN assets a ON a.user_id = al.owner_id
    LEFT JOIN exif e ON e.asset_id = a.id
    WHERE al.id = p_album AND al.rules IS NOT NULL
      AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.live_photo_of IS NULL
      AND album_rules_match(al.rules, a.id, a.kind, a.local_at, e.make, e.model)
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION album_has_asset(p_album uuid, p_asset uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1
        FROM assets asked
        JOIN assets a ON a.id = COALESCE(asked.live_photo_of, asked.id)
        JOIN albums al ON al.id = p_album
        LEFT JOIN exif e ON e.asset_id = a.id
        WHERE asked.id = p_asset AND asked.deleted_at IS NULL AND a.deleted_at IS NULL AND a.status = 'ready'
          AND CASE WHEN al.rules IS NULL
                THEN EXISTS (SELECT 1 FROM album_assets aa WHERE aa.album_id = p_album AND aa.asset_id = a.id)
                ELSE a.user_id = al.owner_id AND a.archived_at IS NULL
                     AND album_rules_match(al.rules, a.id, a.kind, a.local_at, e.make, e.model)
              END
    )
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION asset_visible_to(p_asset uuid, p_user uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM assets a
        WHERE a.id = p_asset AND a.deleted_at IS NULL AND (
            a.user_id = p_user
            OR (a.archived_at IS NULL AND EXISTS (
                SELECT 1 FROM partner_shares ps
                WHERE ps.owner_id = a.user_id AND ps.partner_id = p_user
                  AND (ps.since_at IS NULL OR a.local_at >= ps.since_at)))
            OR EXISTS (
                SELECT 1 FROM albums al
                WHERE (al.owner_id = p_user OR EXISTS (
                        SELECT 1 FROM album_members m WHERE m.album_id = al.id AND m.user_id = p_user))
                  AND album_has_asset(al.id, p_asset))
        )
    )
$$;
-- +goose StatementEnd

DROP TABLE asset_tags;
DROP TABLE tags;
DROP TABLE vault_sessions;
DROP INDEX assets_trash_idx;
DROP INDEX assets_timeline_idx;
CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND live_photo_of IS NULL;
ALTER TABLE users DROP COLUMN vault_pin_hash;
ALTER TABLE assets DROP COLUMN vault_at;
