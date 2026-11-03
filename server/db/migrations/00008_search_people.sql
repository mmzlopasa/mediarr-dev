-- +goose Up
CREATE TABLE asset_search (
    asset_id uuid PRIMARY KEY REFERENCES assets (id) ON DELETE CASCADE,
    embedding vector(768) NOT NULL,
    ocr_text text NOT NULL DEFAULT '',
    ocr_tsv tsvector GENERATED ALWAYS AS (to_tsvector('simple', ocr_text)) STORED,
    analyzed_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX asset_search_embedding_idx ON asset_search USING hnsw (embedding vector_cosine_ops);
CREATE INDEX asset_search_ocr_idx ON asset_search USING gin (ocr_tsv);

CREATE TABLE people (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name text NOT NULL DEFAULT '',
    hidden boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX people_user_idx ON people (user_id);

CREATE TABLE faces (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id uuid NOT NULL REFERENCES assets (id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    person_id uuid REFERENCES people (id) ON DELETE SET NULL,
    x1 real NOT NULL,
    y1 real NOT NULL,
    x2 real NOT NULL,
    y2 real NOT NULL,
    score real NOT NULL,
    embedding vector(512) NOT NULL
);
CREATE INDEX faces_asset_idx ON faces (asset_id);
CREATE INDEX faces_person_idx ON faces (person_id);
CREATE INDEX faces_embedding_idx ON faces USING hnsw (embedding vector_cosine_ops);

-- Smart albums also by person, tag and place, now that those exist.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION album_rules_match(
    rules jsonb, p_asset uuid, p_kind text, p_local_at timestamp, p_make text, p_model text
) RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT (rules->>'from' IS NULL OR p_local_at >= (rules->>'from')::date)
       AND (rules->>'to' IS NULL OR p_local_at < (rules->>'to')::date + 1)
       AND (rules->>'kind' IS NULL OR rules->>'kind' = p_kind
            OR (rules->>'kind' = 'live' AND EXISTS (
                SELECT 1 FROM assets v WHERE v.live_photo_of = p_asset AND v.deleted_at IS NULL)))
       AND (rules->>'camera' IS NULL
            OR lower(trim(coalesce(p_make, '') || ' ' || coalesce(p_model, ''))) = lower(rules->>'camera'))
       AND (rules->>'person' IS NULL OR EXISTS (
            SELECT 1 FROM faces f WHERE f.asset_id = p_asset AND f.person_id = (rules->>'person')::uuid))
       AND (rules->>'tag' IS NULL OR EXISTS (
            SELECT 1 FROM asset_tags x WHERE x.asset_id = p_asset AND x.tag_id = (rules->>'tag')::uuid))
       AND (rules->>'place' IS NULL OR EXISTS (
            SELECT 1 FROM exif e WHERE e.asset_id = p_asset AND lower(rules->>'place') IN (lower(e.city), lower(e.state), lower(e.country))))
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION album_rules_match(
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

DROP TABLE faces;
DROP TABLE people;
DROP TABLE asset_search;
