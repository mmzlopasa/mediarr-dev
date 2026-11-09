-- +goose Up
-- Clean up finds screenshots among many photos quickly: by a name in many languages or a PNG in the
-- shape of a screen, kept in the row, and by the mark an iPhone leaves in the EXIF.
ALTER TABLE assets ADD COLUMN screenshot_hint boolean GENERATED ALWAYS AS (
    original_name ~* '(screenshot|screen ?shot|snimka zaslona|snimak ekrana|bildschirmfoto|capture d.[ée]cran|schermata|captura de pantalla|zrzut ekranu|sn[ií]mek obrazovky|снимок экрана)'
    OR (mime_type = 'image/png' AND width > 0 AND height > 0
        AND greatest(width, height)::real / least(width, height) >= 1.6)
) STORED;
CREATE INDEX assets_screenshot_hint ON assets (user_id) WHERE screenshot_hint AND deleted_at IS NULL;
CREATE INDEX exif_screenshot ON exif (asset_id) WHERE raw->>'UserComment' = 'Screenshot';

-- +goose Down
DROP INDEX IF EXISTS exif_screenshot;
DROP INDEX IF EXISTS assets_screenshot_hint;
ALTER TABLE assets DROP COLUMN IF EXISTS screenshot_hint;
