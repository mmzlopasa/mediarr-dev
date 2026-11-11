---
title: "Install Mediarr with Docker Compose"
sidebar_label: Docker Compose
description: "Install Mediarr on your own server with Docker Compose: two files, one command, and the first account in a few minutes."
---

# Install with Docker Compose

Run these commands one at a time on your server.

## 1. Make a folder

```bash
mkdir -p ~/mediarr && cd ~/mediarr
```

## 2. Download the two files

```bash
curl -fsSL -o docker-compose.yml https://cdn.mediarr.app/install/docker-compose.yml
curl -fsSL -o .env https://cdn.mediarr.app/install/example.env
```

## 3. Edit `.env`

```bash
nano .env
```

Change these values:

| Setting | What to put |
| --- | --- |
| `DB_PASSWORD` | A long random password, **with only letters and digits** |
| `UPLOAD_LOCATION` | Absolute path for your originals, such as `/home/you/mediarr/library` |
| `CACHE_LOCATION` | Absolute path for thumbnails, such as `/home/you/mediarr/cache` |
| `DB_LOCATION` | Absolute path for the database, on a local disk |
| `PUID`, `PGID` | Your user and group. The commands `id -u` and `id -g` show them |

This makes a suitable password:

```bash
openssl rand -hex 24
```

## 4. Make the folders

Make them yourself, so that they belong to your user and not to root. Use the paths from your `.env`:

```bash
mkdir -p /home/you/mediarr/library /home/you/mediarr/cache /home/you/mediarr/db
```

## 5. Start Mediarr

```bash
docker compose up -d
```

The first start downloads the images, which takes a few minutes. This shows when everything is running:

```bash
docker compose ps
```

## 6. Open it

Go to `http://your-server-ip:9851` and create the first account, which becomes the administrator. Then continue with the [first steps](/install/post-install).

:::warning Do not open this port to the internet
Ports published by Docker bypass firewalls such as `ufw`. To reach Mediarr from outside, put a [reverse proxy with HTTPS](/administration/reverse-proxy) in front of it, or use a VPN.
:::

## Optional parts

These are turned on in `.env`, then applied with `docker compose up -d`:

- [Smart search and faces](/features/smart-search)
- [AI descriptions](/features/ai-descriptions)
- [External library](/features/external-library)
- [Backups to a folder](/administration/backup)

All settings are listed under [environment variables](/install/environment-variables).
