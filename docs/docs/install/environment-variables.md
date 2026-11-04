---
title: Environment variables
---

# Environment variables

Mediarr reads these from `.env`. After changing them, apply them with `docker compose up -d`.

## Required

| Variable | Meaning |
| --- | --- |
| `MEDIARR_VERSION` | The version to run, `latest` or a number |
| `DB_USER` | Database user. Letters and digits only |
| `DB_PASSWORD` | Database password. Letters and digits only |
| `UPLOAD_LOCATION` | Absolute path for your original files |
| `CACHE_LOCATION` | Absolute path for thumbnails and video versions |
| `DB_LOCATION` | Absolute path for the database, on a local disk |
| `PUID`, `PGID` | The user and group that own `UPLOAD_LOCATION` and `CACHE_LOCATION` |
| `BIND_ADDRESS` | The address to listen on. Use `127.0.0.1` behind your own reverse proxy |
| `HTTP_PORT` | The port Mediarr opens on. Default `9851` |

## Optional

| Variable | Meaning |
| --- | --- |
| `COMPOSE_PROFILES` | Optional services: `ml`, `ai`, or `ml,ai` |
| `ML_URL` | `http://ml:8000` turns on smart search and faces |
| `ML_FACE_MODEL` | `buffalo_l`, or `buffalo_s`, which is smaller and faster but less accurate |
| `ML_THREADS` | Processor threads for analysis. Default: all of them |
| `EXTERNAL_LIBRARY_PATH` | A folder of photos to show without copying them, read only |
| `BACKUP_PATH` | A folder for backups, best on another disk |
| `TRUSTED_PROXY_HOPS` | How many reverse proxies stand in front of Mediarr, usually `1` |
| `MAX_UPLOAD_MB` | The largest single upload. Default: limited only by free disk space |
| `WORKER_CONCURRENCY` | Background jobs at once. Default: half of the processor cores |
| `VIDEO_ACCEL` | Video encoding hardware: `none`, `qsv`, `nvenc` or `vaapi` |
| `METRICS_TOKEN` | Turns on `/metrics` for Prometheus, using this as a bearer token |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Sends traces to an OpenTelemetry collector |
