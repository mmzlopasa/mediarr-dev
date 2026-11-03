-- name: CountPlaces :one
SELECT count(*) FROM places;

-- name: GeocodeAsset :exec
UPDATE exif e
SET city = p.name, state = p.state, country = p.country, geocoded_at = now()
FROM (
    SELECT x.asset_id, n.name, n.state, n.country
    FROM exif x
    LEFT JOIN LATERAL (
        SELECT q.name, q.state, q.country FROM places q
        WHERE q.lat BETWEEN x.latitude - 1 AND x.latitude + 1
          AND q.lon BETWEEN x.longitude - 2 AND x.longitude + 2
        ORDER BY power(q.lat - x.latitude, 2) + power((q.lon - x.longitude) * cos(radians(x.latitude)), 2)
        LIMIT 1
    ) n ON true
    WHERE x.asset_id = $1 AND x.latitude IS NOT NULL AND EXISTS (SELECT 1 FROM places)
) p
WHERE e.asset_id = p.asset_id;

-- name: ListGeocodePending :many
SELECT asset_id FROM exif WHERE latitude IS NOT NULL AND geocoded_at IS NULL LIMIT 1000;

-- name: MapPoints :many
SELECT a.id, a.kind, a.local_at, e.latitude::float8 AS latitude, e.longitude::float8 AS longitude,
       COALESCE(e.city, '')::text AS city, COALESCE(e.country, '')::text AS country
FROM assets a
JOIN exif e ON e.asset_id = a.id
WHERE a.status = 'ready' AND a.deleted_at IS NULL AND a.archived_at IS NULL AND a.vault_at IS NULL AND a.live_photo_of IS NULL
  AND e.latitude IS NOT NULL AND e.longitude IS NOT NULL
  AND (sqlc.narg('from_at')::timestamp IS NULL OR a.local_at >= sqlc.narg('from_at'))
  AND (sqlc.narg('to_at')::timestamp IS NULL OR a.local_at < sqlc.narg('to_at'))
  AND (a.user_id = sqlc.arg('user_id') OR EXISTS (
      SELECT 1 FROM partner_shares ps
      WHERE ps.owner_id = a.user_id AND ps.partner_id = sqlc.arg('user_id') AND ps.in_timeline
        AND (ps.since_at IS NULL OR a.local_at >= ps.since_at)))
ORDER BY a.local_at, a.id;
