-- Fills a database with 100k asset rows, without files, to test migrations at scale.
BEGIN;
INSERT INTO users (email, name, password_hash, is_admin)
VALUES ('seed@example.invalid', 'Seed', 'unusable', false)
ON CONFLICT (email) DO NOTHING;
INSERT INTO libraries (user_id, name, kind)
SELECT id, 'Uploads', 'upload' FROM users WHERE email = 'seed@example.invalid'
ON CONFLICT DO NOTHING;
INSERT INTO assets (user_id, library_id, checksum, original_name, original_path, size_bytes, mime_type, kind, status, width, height, taken_at, taken_offset_minutes)
SELECT u.id, l.id, sha256(('seed-' || n)::text::bytea), 'IMG_' || n || '.jpg', '/data/library/seed/' || n || '.jpg',
       3000000 + n, 'image/jpeg', 'photo', 'ready', 4032, 3024,
       now() - (n || ' minutes')::interval, 60
FROM users u JOIN libraries l ON l.user_id = u.id, generate_series(1, 100000) AS n
WHERE u.email = 'seed@example.invalid'
ON CONFLICT DO NOTHING;
COMMIT;
SELECT count(*) AS assets FROM assets;
