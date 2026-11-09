-- +goose Up
-- The language a person chose, so the web, the app and e-mails follow it on every device. Empty until
-- they choose: the first device they use then gives the language it already had.
ALTER TABLE users ADD COLUMN language text;

-- +goose Down
ALTER TABLE users DROP COLUMN IF EXISTS language;
