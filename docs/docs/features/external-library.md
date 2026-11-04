---
title: External library
---

# External library

An external library shows a folder of photos you already have, without copying them. Mediarr only reads it, so nothing there is ever changed or deleted.

## Setting it up

1. Add the path to `.env`:

   ```bash
   EXTERNAL_LIBRARY_PATH=/path/to/your/photos
   ```

2. Apply it:

   ```bash
   docker compose up -d
   ```

3. Under **Admin → Settings → External library**, choose whose photos these are, then press **Save and scan**.

The user set by `PUID` must be allowed to read the folder. Once a scan has imported files, the owner can no longer change.

## Changes

Changes on a local disk are noticed at once. On a network share such as SMB that does not work, so changes appear after the scan that runs every 6 hours, or when you press **Scan now**.

A file that disappears is marked as unavailable, not deleted, because a disk may only be disconnected for a while. Files you already have in your library do not get a second entry.
