---
title: A copy at a relative's
---

# A copy at a relative's

A backup in the same house as the server can be lost with it. Two Mediarr servers, yours and a relative's or a friend's, can keep an encrypted copy of each other's backup. Nothing else is needed: no cloud account and no extra service.

- The copy is encrypted with **your** backup password before it leaves your server. The server that keeps it cannot read it, and sees only how much space it takes and when it last came.
- When your server deletes old backups, the other server does not delete them at once: it keeps them for **90 days**. If someone takes over your server and deletes its backups, they can be brought back.
- It is a copy **besides** your usual backup (a folder, a disk, S3 or B2), and it runs at the same hour.

Everything below can be done in the web app under **Admin → Settings**, or in the mobile app under **Account → Backup**.

## On the server that keeps the copy

1. Under **A copy at a relative's → I keep for others**, choose **Invite**.
2. Give a name, how many GB it may keep, and the address at which the other server reaches yours. It needs to be reachable from there: over the internet with your own domain, or over a VPN such as Tailscale.
3. Mediarr shows a **code** and its QR code. Send it to the other server's administrator. It works once, within seven days.

The list shows each guest with the space it takes, its last backup and what it deleted that is still kept. From there you can stop taking its backup, change how much it may keep, bring back what it deleted, or remove it. Removing deletes its copy, so you are asked to type its name.

:::warning Over plain HTTP
The copy is encrypted either way, but its key can be read on the way over plain `http://` outside your home network. Use HTTPS, or a VPN.
:::

## On the server whose backup is copied

1. Set the backup password under **Backup**, if it is not set. The copy is encrypted with it. **Write it down somewhere other than the server**: without it, the copy can never be opened.
2. Turn on **Scheduled backup** under **Additions**.
3. Under **A copy at a relative's → My copy at others**, paste the code, or scan its QR code in the mobile app, and choose **Pair**.

From then on, every backup goes there too. **Test bringing it back** beside each copy brings the newest one back into a temporary place and checks every file. If the copy has not gone out for three days, the administrators of both servers are told.

## Bringing your library back from the copy

If your server is lost, its own credentials for the copy are lost with it. So:

1. Ask the administrator of the other server for a **new code** (beside your name, **New code**). It replaces the old credentials.
2. Install Mediarr as usual with [Docker Compose](/install/docker-compose), but **do not create an account**.
3. Stop the server and worker, leaving the database running:

   ```bash
   docker compose stop server worker
   ```

4. Bring the backup back with the code and your backup password:

   ```bash
   docker compose run --rm --no-deps -e MEDIARR_KEEP_CODE='mediarr-keep:…' -e RESTIC_PASSWORD=your-backup-password server restore-backup
   ```

5. Start everything again:

   ```bash
   docker compose up -d
   ```

Then pair again under **My copy at others**, with another new code, so that backups go there again.
