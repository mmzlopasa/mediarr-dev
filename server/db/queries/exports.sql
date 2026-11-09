-- name: CreateExport :one
INSERT INTO exports (user_id, created_by) VALUES ($1, $2) RETURNING id;

-- name: GetExport :one
SELECT e.*, coalesce(b.name, '')::text AS started_by_name, coalesce(o.email, '')::text AS user_email
FROM exports e
LEFT JOIN users b ON b.id = e.created_by
JOIN users o ON o.id = e.user_id
WHERE e.id = $1;

-- name: ListUserExports :many
SELECT id FROM exports WHERE user_id = $1 ORDER BY created_at DESC LIMIT 20;

-- name: ListAllExports :many
SELECT id FROM exports ORDER BY created_at DESC LIMIT 50;

-- name: ListExportParts :many
SELECT * FROM export_parts WHERE export_id = $1 ORDER BY number;

-- name: GetExportPart :one
SELECT * FROM export_parts WHERE export_id = $1 AND number = $2;

-- name: ExportEstimate :one
-- What an export of a library would take: its own originals and their sidecars. Files in an external
-- library, in the trash or in the locked folder are not exported.
SELECT count(*)::bigint AS files,
       (coalesce(sum(a.size_bytes), 0) + coalesce(sum(s.size_bytes), 0))::bigint AS bytes
FROM assets a
JOIN libraries l ON l.id = a.library_id AND l.kind = 'upload'
LEFT JOIN asset_files s ON s.asset_id = a.id AND s.kind = 'sidecar'
WHERE a.user_id = $1 AND a.deleted_at IS NULL AND a.vault_at IS NULL;

-- name: ListExportCandidates :many
-- Everything of the owner the export holds, oldest id first, from before the export was asked for.
SELECT a.id, a.original_name, a.local_at, a.size_bytes, (l.kind = 'external')::boolean AS external
FROM assets a
JOIN libraries l ON l.id = a.library_id
WHERE a.user_id = $1 AND a.deleted_at IS NULL AND a.vault_at IS NULL AND a.created_at <= $2
ORDER BY a.id;

-- name: AddExportFiles :exec
INSERT INTO export_files (export_id, asset_id, path)
SELECT sqlc.arg('export_id'), unnest(sqlc.arg('asset_ids')::uuid[]), unnest(sqlc.arg('paths')::text[])
ON CONFLICT DO NOTHING;

-- name: PlanExport :exec
UPDATE exports SET planned_at = now(), total_files = $2, total_bytes = $3 WHERE id = $1;

-- name: ForgetUnfinishedExportParts :exec
-- After a restart: files that went into a part that was not finished are made again.
UPDATE export_files f SET part = NULL, sidecar = false, missing = false
WHERE f.export_id = $1 AND f.part IS NOT NULL
  AND f.part NOT IN (SELECT p.number FROM export_parts p WHERE p.export_id = $1);

-- name: ExportDone :one
-- What finished parts hold, to go on from there after a restart.
SELECT count(*) FILTER (WHERE NOT f.missing)::integer AS files, coalesce(sum(a.size_bytes), 0)::bigint AS bytes,
       count(*) FILTER (WHERE f.missing)::integer AS missing
FROM export_files f JOIN assets a ON a.id = f.asset_id
WHERE f.export_id = $1 AND f.part IS NOT NULL AND f.path <> '';

-- name: ListPendingExportFiles :many
-- The next files still to be packed, with where they are and their sidecar.
SELECT f.asset_id, f.path, a.original_path, a.size_bytes, a.user_id, coalesce(s.path, '')::text AS sidecar_path
FROM export_files f
JOIN assets a ON a.id = f.asset_id
LEFT JOIN asset_files s ON s.asset_id = f.asset_id AND s.kind = 'sidecar'
WHERE f.export_id = $1 AND f.part IS NULL AND f.path <> '' AND f.asset_id > $2
ORDER BY f.asset_id
LIMIT $3;

-- name: MarkExportFiles :exec
UPDATE export_files f SET part = sqlc.arg('part'), sidecar = v.sidecar, missing = v.missing
FROM (SELECT unnest(sqlc.arg('asset_ids')::uuid[]) AS asset_id, unnest(sqlc.arg('sidecars')::boolean[]) AS sidecar,
             unnest(sqlc.arg('missing')::boolean[]) AS missing) v
WHERE f.export_id = sqlc.arg('export_id') AND f.asset_id = v.asset_id;

-- name: AddExportPart :exec
INSERT INTO export_parts (export_id, number, size_bytes, files) VALUES ($1, $2, $3, $4)
ON CONFLICT (export_id, number) DO UPDATE SET size_bytes = EXCLUDED.size_bytes, files = EXCLUDED.files, created_at = now();

-- name: SetExportProgress :exec
UPDATE exports SET done_files = $2, done_bytes = $3, missing = $4 WHERE id = $1 AND status = 'running';

-- name: GetExportStatus :one
SELECT status FROM exports WHERE id = $1;

-- name: FinishExport :exec
UPDATE exports SET status = $2, last_error = $3, finished_at = now(),
    expires_at = CASE WHEN $2 = 'done' THEN now() + interval '7 days' END
WHERE id = $1 AND status = 'running';

-- name: ForgetExportFiles :exec
DELETE FROM export_files WHERE export_id = $1;

-- name: CancelExport :one
UPDATE exports SET status = 'cancelled', finished_at = now() WHERE id = $1 AND status = 'running' RETURNING id;

-- name: DeleteExport :exec
DELETE FROM exports WHERE id = $1;

-- name: ListExpiredExports :many
SELECT id FROM exports WHERE status = 'done' AND expires_at < $1;

-- name: ExpireExport :exec
UPDATE exports SET status = 'removed' WHERE id = $1 AND status = 'done';

-- name: DeleteExportParts :exec
DELETE FROM export_parts WHERE export_id = $1;

-- name: ListKeptExports :many
-- Exports whose folder in the cache is still needed.
SELECT id FROM exports WHERE status IN ('running', 'done');

-- name: ExportAssetsPage :many
-- What the metadata file says about each file, a page at a time.
SELECT a.id, f.path, f.sidecar, f.missing, a.original_name, a.original_path, a.kind, coalesce(a.mime_type, '')::text AS mime_type,
       a.size_bytes, a.checksum, a.taken_at, a.taken_offset_minutes, a.local_at, a.created_at,
       a.width, a.height, a.duration_ms, a.caption, a.rating, a.pick, a.is_favorite, a.archived_at,
       a.live_photo_of, a.stack_parent, a.edits, (l.kind = 'external')::boolean AS external,
       e.latitude, e.longitude, e.city, e.state, e.country, e.make, e.model, e.lens,
       coalesce(d.description, '')::text AS ai_description,
       coalesce((SELECT array_agg(t.name ORDER BY t.name) FROM asset_tags x JOIN tags t ON t.id = x.tag_id
                 WHERE x.asset_id = a.id AND t.user_id = a.user_id), '{}')::text[] AS tags,
       coalesce((SELECT s.path FROM asset_files s WHERE s.asset_id = a.id AND s.kind = 'thumb_large'), '')::text AS preview_path
FROM export_files f
JOIN assets a ON a.id = f.asset_id
JOIN libraries l ON l.id = a.library_id
LEFT JOIN exif e ON e.asset_id = a.id
LEFT JOIN asset_descriptions d ON d.asset_id = a.id
WHERE f.export_id = $1 AND f.asset_id > $2
ORDER BY f.asset_id
LIMIT $3;

-- name: ExportFacesOf :many
SELECT f.asset_id, f.person_id, f.x1, f.y1, f.x2, f.y2
FROM faces f
WHERE f.user_id = sqlc.arg('user_id') AND f.asset_id = ANY(sqlc.arg('asset_ids')::uuid[])
ORDER BY f.asset_id, f.x1, f.id;

-- name: ExportPeople :many
SELECT id, name, birth_date, hidden, created_at FROM people WHERE user_id = $1 ORDER BY created_at, id;

-- name: ExportTags :many
SELECT name FROM tags WHERE user_id = $1 ORDER BY name;

-- name: ExportAlbums :many
-- The owner's own albums, smart ones too, with the files of the export in each. Photos others added to
-- a shared album are theirs, and are left out.
SELECT al.id, al.title, al.description, al.parent_id, al.created_at, al.rules,
       coalesce((SELECT array_agg(f.asset_id ORDER BY f.asset_id) FROM export_files f
                 WHERE f.export_id = sqlc.arg('export_id') AND f.asset_id IN (SELECT album_item_ids(al.id))), '{}')::uuid[] AS assets
FROM albums al
WHERE al.owner_id = sqlc.arg('user_id')
ORDER BY al.created_at, al.id;
