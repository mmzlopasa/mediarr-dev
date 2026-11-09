-- What Clean up offers: photos and videos that are the owner's own, visible, and not kept already.

-- name: CleanupBlurry :many
SELECT a.id, a.original_name, a.size_bytes, a.kind, a.width, a.height, a.aspect_ratio, a.local_at, a.is_favorite,
       a.duration_ms, a.sharpness,
       EXISTS (SELECT 1 FROM album_assets aa WHERE aa.asset_id = a.id) AS in_album
FROM assets a
WHERE a.user_id = $1 AND a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL AND a.sharpness IS NOT NULL
  AND a.sharpness < sqlc.arg('below')::real
ORDER BY a.sharpness, a.id
LIMIT sqlc.arg('max') OFFSET sqlc.arg('skip');

-- name: CountBlurry :one
SELECT count(*), coalesce(sum(a.size_bytes), 0)::bigint AS bytes
FROM assets a
WHERE a.user_id = $1 AND a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL AND a.sharpness IS NOT NULL
  AND a.sharpness < sqlc.arg('below')::real;

-- name: CleanupLargeVideos :many
SELECT a.id, a.original_name, a.size_bytes, a.kind, a.width, a.height, a.aspect_ratio, a.local_at, a.is_favorite,
       a.duration_ms, a.sharpness,
       EXISTS (SELECT 1 FROM album_assets aa WHERE aa.asset_id = a.id) AS in_album
FROM assets a
WHERE a.user_id = $1 AND a.kind = 'video' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL AND a.live_photo_of IS NULL
  AND a.size_bytes >= sqlc.arg('at_least')::bigint
ORDER BY a.size_bytes DESC, a.id
LIMIT sqlc.arg('max') OFFSET sqlc.arg('skip');

-- name: CountLargeVideos :one
SELECT count(*), coalesce(sum(a.size_bytes), 0)::bigint AS bytes
FROM assets a
WHERE a.user_id = $1 AND a.kind = 'video' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL AND a.live_photo_of IS NULL
  AND a.size_bytes >= sqlc.arg('at_least')::bigint;

-- name: CleanupScreenshots :many
-- By the name in many languages, by the mark an iPhone leaves, or a PNG without a camera in the
-- shape of a phone's screen. screenshot_hint holds the first and the shape, so few rows are read.
SELECT a.id, a.original_name, a.size_bytes, a.kind, a.width, a.height, a.aspect_ratio, a.local_at, a.is_favorite,
       a.duration_ms, a.sharpness,
       EXISTS (SELECT 1 FROM album_assets aa WHERE aa.asset_id = a.id) AS in_album
FROM assets a
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = $1 AND a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL
  AND ((a.screenshot_hint AND (a.original_name ~* '(screenshot|screen ?shot|snimka zaslona|snimak ekrana|bildschirmfoto|capture d.[ée]cran|schermata|captura de pantalla|zrzut ekranu|sn[ií]mek obrazovky|снимок экрана)' OR coalesce(e.make, '') = ''))
       OR a.id IN (SELECT x.asset_id FROM exif x WHERE x.raw->>'UserComment' = 'Screenshot'))
ORDER BY a.local_at DESC, a.id
LIMIT sqlc.arg('max') OFFSET sqlc.arg('skip');

-- name: CountScreenshots :one
SELECT count(*), coalesce(sum(a.size_bytes), 0)::bigint AS bytes
FROM assets a
LEFT JOIN exif e ON e.asset_id = a.id
WHERE a.user_id = $1 AND a.kind = 'photo' AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL
  AND ((a.screenshot_hint AND (a.original_name ~* '(screenshot|screen ?shot|snimka zaslona|snimak ekrana|bildschirmfoto|capture d.[ée]cran|schermata|captura de pantalla|zrzut ekranu|sn[ií]mek obrazovky|снимок экрана)' OR coalesce(e.make, '') = ''))
       OR a.id IN (SELECT x.asset_id FROM exif x WHERE x.raw->>'UserComment' = 'Screenshot'));

-- name: CleanupBursts :many
-- The other shots of a burst, beside its best one. A RAW with its JPEG is a pair, not a burst.
SELECT a.id, a.original_name, a.size_bytes, a.kind, a.width, a.height, a.aspect_ratio, a.local_at, a.is_favorite,
       a.duration_ms, a.sharpness,
       EXISTS (SELECT 1 FROM album_assets aa WHERE aa.asset_id = a.id) AS in_album
FROM assets a
JOIN assets m ON m.id = a.stack_parent
WHERE a.user_id = $1 AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL
  AND lower(regexp_replace(a.original_name, '\.[^.]*$', '')) <> lower(regexp_replace(m.original_name, '\.[^.]*$', ''))
ORDER BY a.local_at DESC, a.id
LIMIT sqlc.arg('max') OFFSET sqlc.arg('skip');

-- name: CountBursts :one
SELECT count(*), coalesce(sum(a.size_bytes), 0)::bigint AS bytes
FROM assets a
JOIN assets m ON m.id = a.stack_parent
WHERE a.user_id = $1 AND a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL
  AND a.vault_at IS NULL AND a.cleanup_kept_at IS NULL
  AND lower(regexp_replace(a.original_name, '\.[^.]*$', '')) <> lower(regexp_replace(m.original_name, '\.[^.]*$', ''));

-- name: CountUnfingerprinted :one
SELECT count(*) FROM assets
WHERE user_id = $1 AND kind = 'photo' AND status = 'ready' AND deleted_at IS NULL AND sharpness IS NULL;
