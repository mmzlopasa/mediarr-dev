---
title: FAQ
---

# FAQ

## Does it need a domain or HTTPS?

No. Mediarr works at `http://your-server-ip:9851`. Only passkeys need HTTPS, and the app and browser work without it. For access from outside your network, use [a reverse proxy with HTTPS](/administration/reverse-proxy) or a VPN.

## Do my photos leave my server?

No. Search, faces, places and AI descriptions all run on your server. The only outside request by default is for the map's background, which comes from `cdn.mediarr.app`. You can change it under **Admin → Settings → Map**.

## Are my originals changed?

Never. Edits are stored separately, and an external library is mounted read only.

## Is phone backup a real backup?

No. It copies your phone to the server, so it protects you from losing the phone, not the server. Set up [backups](/administration/backup) as well.

## I forgot my password

See [set a forgotten password](/administration/users#set-a-forgotten-password).

## The first start fails with a permission error

The folders in `.env` must belong to the user set by `PUID` and `PGID`. Docker creates missing folders as root, so make them yourself, as in [step 4](/install/docker-compose#4-make-the-folders).

## `docker compose` says the file is invalid

Your Docker Compose is older than 2.23.1. See [requirements](/install/requirements#software).
