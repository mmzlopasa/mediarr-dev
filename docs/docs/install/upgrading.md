---
title: Upgrading
---

# Upgrading

Make a [backup](/administration/backup) first, then run these in the folder with your `docker-compose.yml`:

```bash
docker compose pull
docker compose up -d
```

The database is updated by itself when the server starts.

To stay on one version, set `MEDIARR_VERSION` in `.env` to that number instead of `latest`.
