---
title: Monitoring
---

# Monitoring

**Admin → Health** and **Admin → Jobs** show the state of the server and its background work.

## Checking the originals

**Admin → Health → Check the originals** looks at every original and lists those that are missing or cannot be read. **Thoroughly** also reads each file and compares its checksum, so it finds files that changed, and takes as long as reading the whole library. A check changes no file. A quick check also runs once a week.

## Maintenance mode

**Admin → Settings → Server → Maintenance mode** keeps everyone except administrators out while you work on the server. People who are signed in see a message, and only administrators can sign in. If you lock yourself out, this turns it off:

```bash
docker compose exec server /mediarr security reset
```

## Background jobs

**Admin → Settings → Server** sets how many background jobs, videos and analyses run at a time. These apply after the worker restarts:

```bash
docker compose restart worker
```

The same place sets how sure a face must be, how alike two faces must be to be one person, and how often an external library is scanned. These apply to work done from then on.

## Prometheus

Set a long random value in `.env`:

```bash
METRICS_TOKEN=choose-a-long-random-value
```

Prometheus can then read `/metrics`, using that value as a bearer token. A dashboard for Grafana is available as [grafana-dashboard.json](/install/grafana-dashboard.json).

## Traces

Set `OTEL_EXPORTER_OTLP_ENDPOINT` to the address of an OpenTelemetry collector. Without it, no traces are sent anywhere.
