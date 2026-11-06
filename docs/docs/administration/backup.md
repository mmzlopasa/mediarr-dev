---
title: Backup and restore
---

# Backup and restore

Mediarr makes encrypted backups of your database and originals with [restic](https://restic.net). Set them up under **Admin → Settings**.

:::danger Keep the backup password somewhere safe
Without it, a backup cannot be opened by anyone. If you lose the server, you need this password and the destination to get your library back.
:::

## Destinations

- **A folder or disk.** Add `BACKUP_PATH=/path/to/backups` to `.env` and run `docker compose up -d`. The user set by `PUID` must be allowed to write there.
- **S3 or S3-compatible storage.**
- **Backblaze B2.**
- **Another Mediarr**, a relative's or a friend's, as a copy besides the destination above. See [A copy at a relative's](/administration/keep).

Old backups are thinned out by themselves. **Test bringing it back** really restores the newest backup into a temporary place and checks it, so it needs free disk space about the size of your library.

## Restoring onto a new server

1. Install Mediarr as usual with [Docker Compose](/install/docker-compose), but **do not create an account**.
2. Stop the server and worker, leaving the database running:

   ```bash
   docker compose stop server worker
   ```

3. Bring the backup back. For a folder, use `/backup` as the repository after setting `BACKUP_PATH` in `.env`:

   ```bash
   docker compose run --rm --no-deps -e RESTIC_REPOSITORY=/backup -e RESTIC_PASSWORD=your-backup-password server restore-backup
   ```

   For S3, use `s3:https://your-endpoint/your-bucket` as the repository and also pass `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

4. Start everything again:

   ```bash
   docker compose up -d
   ```

Thumbnails are not part of a backup, and are made again by themselves.
