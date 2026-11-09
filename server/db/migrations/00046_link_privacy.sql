-- +goose Up
-- Privacy of a public link: faces that are blurred, details that are taken out of downloads, and
-- who opened it. A visit keeps a rough place, never the address it came from.
ALTER TABLE share_links
    ADD COLUMN hide_faces text NOT NULL DEFAULT 'none' CHECK (hide_faces IN ('none', 'all', 'except')),
    ADD COLUMN strip_camera boolean NOT NULL DEFAULT false,
    ADD COLUMN strip_date boolean NOT NULL DEFAULT false,
    ADD COLUMN ask_name boolean NOT NULL DEFAULT false,
    ADD COLUMN privacy_version integer NOT NULL DEFAULT 0;

CREATE TABLE share_link_visible_people (
    link_id uuid NOT NULL REFERENCES share_links (id) ON DELETE CASCADE,
    person_id uuid NOT NULL REFERENCES people (id) ON DELETE CASCADE,
    PRIMARY KEY (link_id, person_id)
);

CREATE TABLE share_link_visits (
    id bigserial PRIMARY KEY,
    link_id uuid NOT NULL REFERENCES share_links (id) ON DELETE CASCADE,
    visitor_hash bytea NOT NULL,
    at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL DEFAULT '',
    city text NOT NULL DEFAULT '',
    country text NOT NULL DEFAULT '',
    device text NOT NULL DEFAULT '',
    viewed integer NOT NULL DEFAULT 0,
    downloaded integer NOT NULL DEFAULT 0,
    UNIQUE (link_id, visitor_hash)
);
CREATE INDEX share_link_visits_at ON share_link_visits (link_id, at DESC);

-- +goose Down
DROP TABLE IF EXISTS share_link_visits;
DROP TABLE IF EXISTS share_link_visible_people;
ALTER TABLE share_links
    DROP COLUMN IF EXISTS privacy_version,
    DROP COLUMN IF EXISTS ask_name,
    DROP COLUMN IF EXISTS strip_date,
    DROP COLUMN IF EXISTS strip_camera,
    DROP COLUMN IF EXISTS hide_faces;
