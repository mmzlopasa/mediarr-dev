---
slug: /
title: Overview
sidebar_position: 1
---

# Mediarr

Mediarr is a photo and video library that you run on your own server. Your phone backs up to it, you browse it from a browser or the app, and every file stays on your own disk.

## What it does

- **Automatic backup** from iPhone and Android, in the background.
- **A fast timeline** of everything you own, with albums, favourites, archive, trash and a locked vault.
- **Smart search** in plain language, in many languages, including text inside pictures.
- **People**, found by recognising faces, all on your server.
- **Map and places**, worked out offline, with trips made automatically.
- **Sharing** through partners, shared albums and public links.
- **Non-destructive editing**: originals are never changed.
- **Import** from Immich, Google Takeout and iCloud.
- **Backups** to a folder, S3 or Backblaze B2, with a test that really brings them back.

## How it runs

You need two files, `docker-compose.yml` and `.env`. Mediarr then opens at `http://your-server-ip:9851`. A domain name and HTTPS are up to you, and everything except passkeys works without them.

Smart search, faces and AI descriptions are optional. Everything else works without them, which suits smaller servers.

## Where to start

1. Check the [requirements](/install/requirements).
2. [Install with Docker Compose](/install/docker-compose).
3. Follow the [first steps](/install/post-install).

You can look around first at [demo.mediarr.app](https://demo.mediarr.app).

**Explore** brings together the people, places and memories in your library. It is in the menu on the web and under Library in the app.
