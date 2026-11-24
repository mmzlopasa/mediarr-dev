---
title: Monitoring
---

# Monitoring

**Admin → Health** and **Admin → Jobs** show the state of the server and its background work.

## Checking the originals

**Admin → Health → Check the originals** looks at every original and lists those that are missing or cannot be read. **Thoroughly** also reads each file and compares its checksum, so it finds files that changed, and takes as long as reading the whole library. A check changes no file. A quick check also runs once a week.

## Maintenance mode

**Admin → Settings → Server → Maintenance mode** keeps everyone except administrators out while you work on the server. People who are signed in see a message, and only administrators can sign in. If you lock yourself out, this turns it off, along with the rules under **Admin → Security**:

```bash
docker compose exec server /mediarr security reset
```

## Background jobs

**Admin → Settings → Server** sets how many background jobs (0 uses `WORKER_CONCURRENCY` from `.env`, or the number of processors), **Videos at a time** and **Analyses at a time** (1 each by default) run. These apply after the worker restarts:

```bash
docker compose restart worker
```

The same place sets how sure a face must be, how alike two faces must be to be one person, and how often an external library is scanned (every 6 hours by default). These apply to work done from then on.

## A dashboard for your services

A dashboard that watches your services can read Mediarr's numbers from `/api/stats`:

1. Sign in as an administrator, open **Account → API keys** and make a key with only **Read**. The key cannot change anything, and it is shown once.
2. In the dashboard, set the address of Mediarr (for example `http://your-server-ip:9851`), the header `X-Api-Key` with that key, and the path `/api/stats`.

The answer is JSON:

| Field | What it holds |
| --- | --- |
| `photos`, `videos` | How many there are in the whole library |
| `usageBytes` | The total size of all originals |
| `users` | How many accounts there are |
| `processing`, `failed` | Files still being prepared, and files that could not be |
| `diskTotalBytes`, `diskFreeBytes` | The disk of the library |
| `lastUploadAt` | When the newest file arrived; absent in an empty library |
| `version` | The version of the server |
| `jobs` | A list with one entry per queue of background work: `queue`, `queued`, `running` and `failed` |

To be warned about background work that failed, add up `failed` of every entry in `jobs`.

## Prometheus

Set a long random value in `.env`:

```bash
METRICS_TOKEN=choose-a-long-random-value
```

Prometheus can then read `/metrics`, using that value as a bearer token. A dashboard for Grafana is available as [grafana-dashboard.json](/install/grafana-dashboard.json).

## Traces

Set `OTEL_EXPORTER_OTLP_ENDPOINT` to the address of an OpenTelemetry collector. Without it, no traces are sent anywhere.
