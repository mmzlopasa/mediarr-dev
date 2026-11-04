---
title: Uninstalling
---

# Uninstalling

This stops Mediarr and removes its containers:

```bash
docker compose down
```

Your files stay where they are: the originals in `UPLOAD_LOCATION`, thumbnails in `CACHE_LOCATION` and the database in `DB_LOCATION`. To remove those too, delete the folders yourself, after checking that you have a copy of your originals.
