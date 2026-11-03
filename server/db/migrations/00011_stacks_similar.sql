-- +goose Up
ALTER TABLE assets
    ADD COLUMN stack_parent uuid REFERENCES assets (id) ON DELETE SET NULL,
    ADD COLUMN stack_free boolean NOT NULL DEFAULT false,
    ADD COLUMN stack_chosen boolean NOT NULL DEFAULT false,
    ADD COLUMN phash bigint,
    ADD COLUMN sharpness real,
    ADD COLUMN organized_at timestamptz;

CREATE INDEX assets_stack_parent_idx ON assets (stack_parent) WHERE stack_parent IS NOT NULL;
CREATE INDEX assets_unorganized_idx ON assets (user_id) WHERE organized_at IS NULL AND kind = 'photo' AND status = 'ready';

DROP INDEX assets_timeline_idx;
CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND vault_at IS NULL
      AND live_photo_of IS NULL AND stack_parent IS NULL;

ALTER TABLE asset_search ADD COLUMN similar_checked boolean NOT NULL DEFAULT false;
CREATE INDEX asset_search_unchecked_idx ON asset_search (asset_id) WHERE NOT similar_checked;

-- Pairs that look alike. A proposal only: nothing here ever removes a photo.
CREATE TABLE similar_pairs (
    a_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    b_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    dismissed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (a_id, b_id),
    CHECK (a_id < b_id)
);
CREATE INDEX similar_pairs_user_idx ON similar_pairs (user_id) WHERE dismissed_at IS NULL;
CREATE INDEX similar_pairs_b_idx ON similar_pairs (b_id);

-- A shot that goes to the trash, the archive or the vault leaves its stack, so nothing stays hidden
-- behind it. If it was the main shot, the sharpest one left takes over, wherever the change came from.
-- +goose StatementBegin
CREATE FUNCTION assets_leave_stack() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    heir uuid;
BEGIN
    IF NEW.stack_parent IS NOT NULL THEN
        UPDATE assets SET stack_parent = NULL WHERE id = NEW.id;
    END IF;
    SELECT id INTO heir FROM assets
    WHERE stack_parent = NEW.id AND deleted_at IS NULL AND archived_at IS NULL AND vault_at IS NULL
    ORDER BY sharpness DESC NULLS LAST, id LIMIT 1;
    UPDATE assets SET stack_parent = CASE WHEN id = heir THEN NULL ELSE heir END WHERE stack_parent = NEW.id;
    RETURN NULL;
END
$$;
-- +goose StatementEnd
CREATE TRIGGER assets_leave_stack_trigger AFTER UPDATE OF deleted_at, archived_at, vault_at ON assets
    FOR EACH ROW WHEN (NEW.deleted_at IS NOT NULL OR NEW.archived_at IS NOT NULL OR NEW.vault_at IS NOT NULL)
    EXECUTE FUNCTION assets_leave_stack();

-- A smart album shows the main shot of a stack. A shot put into an album by hand stays there.
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
      AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL
      AND a.live_photo_of IS NULL AND a.stack_parent IS NULL
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
                ELSE a.user_id = al.owner_id AND a.archived_at IS NULL AND a.stack_parent IS NULL
                     AND album_rules_match(al.rules, a.id, a.kind, a.local_at, e.make, e.model)
              END
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

DROP TRIGGER assets_leave_stack_trigger ON assets;
DROP FUNCTION assets_leave_stack();
DROP TABLE similar_pairs;
DROP INDEX asset_search_unchecked_idx;
ALTER TABLE asset_search DROP COLUMN similar_checked;
DROP INDEX assets_timeline_idx;
CREATE INDEX assets_timeline_idx ON assets (user_id, local_at DESC, id DESC)
    WHERE status = 'ready' AND deleted_at IS NULL AND archived_at IS NULL AND vault_at IS NULL AND live_photo_of IS NULL;
DROP INDEX assets_unorganized_idx;
DROP INDEX assets_stack_parent_idx;
ALTER TABLE assets
    DROP COLUMN organized_at,
    DROP COLUMN sharpness,
    DROP COLUMN phash,
    DROP COLUMN stack_chosen,
    DROP COLUMN stack_free,
    DROP COLUMN stack_parent;
