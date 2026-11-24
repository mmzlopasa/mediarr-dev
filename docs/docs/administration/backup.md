---
title: Backup and restore
---

# Backup and restore

Mediarr makes encrypted backups of your database and originals with [restic](https://restic.net). Set them up under **Admin → Settings → Backup**: the **Destination**, the **Backup password**, an **Access key** and **Secret key** for S3 or B2, and the **Hour of the day (0-23)**, 3 by default. Then turn on **Scheduled backup** under **Admin → Settings → Additions**: without it, backups run only when you choose **Back up now**.

:::danger Keep the backup password somewhere safe
Without it, a backup cannot be opened by anyone. If you lose the server, you need this password and the destination to get your library back.
:::

## Destinations

- **A folder or disk.** Add `BACKUP_PATH=/path/to/backups` to `.env` and run `docker compose up -d`. The destination is then a folder inside `/backup`. The user set by `PUID` must be allowed to write there.
- **S3 or S3-compatible storage**, as `s3:https://your-endpoint/your-bucket`.
- **Backblaze B2**, as `b2:your-bucket:a-folder`.
- **Another Mediarr**, a relative's or a friend's, as a copy besides the destination above. See [A copy at a relative's](/administration/keep).

Old backups are thinned out by themselves: one a day is kept for 7 days, one a week for 4 weeks and one a month for 12 months. **Test bringing it back** really restores the newest backup into a temporary place and checks it, so it needs free disk space about the size of your library.

Thumbnails are not part of a backup, and are made again by themselves. An [external library](/features/external-library) is not part of it either: back up that folder yourself.

## Restoring onto a new server

1. Install Mediarr as usual with [Docker Compose](/install/docker-compose), but **do not create an account**.
2. Stop the server and worker, leaving the database running. The restore writes into it, so it must be running:

   ```bash
   docker compose stop server worker
   ```

3. Bring the backup back. For a folder, use `/backup` (or the folder inside it you chose) as the repository after setting `BACKUP_PATH` in `.env`:

   ```bash
   docker compose run --rm --no-deps -e RESTIC_REPOSITORY=/backup -e RESTIC_PASSWORD=your-backup-password server restore-backup
   ```

   For S3, use `s3:https://your-endpoint/your-bucket` as the repository and also pass `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. For B2, use `b2:your-bucket:a-folder` and pass the key ID as `AWS_ACCESS_KEY_ID` and the application key as `AWS_SECRET_ACCESS_KEY`: Mediarr hands them to restic for B2 as well.

4. Start everything again:

   ```bash
   docker compose up -d
   ```
