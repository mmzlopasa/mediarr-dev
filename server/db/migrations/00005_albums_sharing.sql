-- +goose Up
CREATE TABLE albums (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title text NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
    description text NOT NULL DEFAULT '',
    cover_asset_id uuid REFERENCES assets (id) ON DELETE SET NULL,
    asset_order text NOT NULL DEFAULT 'newest' CHECK (asset_order IN ('newest', 'oldest')),
    -- Set only on a smart album. New kinds of rule are new keys, so old albums keep working.
    rules jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX albums_owner_idx ON albums (owner_id);

CREATE TABLE album_assets (
    album_id uuid NOT NULL REFERENCES albums (id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    added_by uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    added_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (album_id, asset_id)
);
CREATE INDEX album_assets_asset_idx ON album_assets (asset_id);

CREATE TABLE album_members (
    album_id uuid NOT NULL REFERENCES albums (id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('viewer', 'contributor', 'editor')),
    added_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (album_id, user_id)
);
CREATE INDEX album_members_user_idx ON album_members (user_id);

CREATE TABLE album_comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    album_id uuid NOT NULL REFERENCES albums (id) ON DELETE CASCADE,
    asset_id uuid REFERENCES assets (id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    body text NOT NULL CHECK (length(body) BETWEEN 1 AND 2000),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX album_comments_album_idx ON album_comments (album_id, asset_id, created_at);

CREATE TABLE album_hearts (
    album_id uuid NOT NULL REFERENCES albums (id) ON DELETE CASCADE,
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (album_id, asset_id, user_id)
);

CREATE TABLE partner_shares (
    owner_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    partner_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    since_at timestamp,
    in_timeline boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (owner_id, partner_id),
    CHECK (owner_id <> partner_id)
);
CREATE INDEX partner_shares_partner_idx ON partner_shares (partner_id);

CREATE TABLE share_links (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    album_id uuid NOT NULL REFERENCES albums (id) ON DELETE CASCADE,
    token_hash bytea NOT NULL UNIQUE,
    label text NOT NULL DEFAULT '',
    password_hash text,
    expires_at timestamptz,
    download_limit integer CHECK (download_limit > 0),
    download_count integer NOT NULL DEFAULT 0,
    allow_download boolean NOT NULL DEFAULT true,
    allow_upload boolean NOT NULL DEFAULT false,
    upload_only boolean NOT NULL DEFAULT false,
    show_location boolean NOT NULL DEFAULT false,
    watermark text,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX share_links_album_idx ON share_links (album_id);

CREATE TABLE share_link_sessions (
    token_hash bytea PRIMARY KEY,
    link_id uuid NOT NULL REFERENCES share_links (id) ON DELETE CASCADE,
    expires_at timestamptz NOT NULL
);

-- +goose StatementBegin
CREATE FUNCTION album_rules_match(
    rules jsonb, p_asset uuid, p_kind text, p_local_at timestamp, p_make text, p_model text
) RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT (rules->>'from' IS NULL OR p_local_at >= (rules->>'from')::date)
       AND (rules->>'to' IS NULL OR p_local_at < (rules->>'to')::date + 1)
       AND (rules->>'kind' IS NULL OR rules->>'kind' = p_kind
            OR (rules->>'kind' = 'live' AND EXISTS (
                SELECT 1 FROM assets v WHERE v.live_photo_of = p_asset AND v.deleted_at IS NULL)))
       AND (rules->>'camera' IS NULL
            OR lower(trim(coalesce(p_make, '') || ' ' || coalesce(p_model, ''))) = lower(rules->>'camera'))
$$;
-- +goose StatementEnd

-- What an album shows. This and album_has_asset must agree, and a test checks that they do.
-- +goose StatementBegin
CREATE FUNCTION album_item_ids(p_album uuid) RETURNS SETOF uuid LANGUAGE sql STABLE AS $$
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

-- One asset at a time, fast enough for every thumbnail. A Live Photo's video follows its photo.
-- +goose StatementBegin
CREATE FUNCTION album_has_asset(p_album uuid, p_asset uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
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

-- The one place that decides who may see an asset. Every file endpoint goes through it.
-- +goose StatementBegin
CREATE FUNCTION asset_visible_to(p_asset uuid, p_user uuid) RETURNS boolean LANGUAGE sql STABLE AS $$
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

-- +goose StatementBegin
CREATE FUNCTION album_asset_count(p_album uuid) RETURNS bigint LANGUAGE sql STABLE AS $$
    SELECT count(*) FROM album_item_ids(p_album)
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE FUNCTION album_newest_asset(p_album uuid) RETURNS uuid LANGUAGE sql STABLE AS $$
    SELECT a.id FROM assets a WHERE a.id IN (SELECT album_item_ids(p_album))
    ORDER BY a.local_at DESC, a.id DESC LIMIT 1
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION album_newest_asset(uuid);
DROP FUNCTION album_asset_count(uuid);
DROP FUNCTION asset_visible_to(uuid, uuid);
DROP FUNCTION album_has_asset(uuid, uuid);
DROP FUNCTION album_item_ids(uuid);
DROP FUNCTION album_rules_match(jsonb, uuid, text, timestamp, text, text);
DROP TABLE share_link_sessions;
DROP TABLE share_links;
DROP TABLE partner_shares;
DROP TABLE album_hearts;
DROP TABLE album_comments;
DROP TABLE album_members;
DROP TABLE album_assets;
DROP TABLE albums;
