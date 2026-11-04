---
title: Monitoring
---

# Monitoring

**Admin → Health** and **Admin → Jobs** show the state of the server and its background work.

## Prometheus

Set a long random value in `.env`:

```bash
METRICS_TOKEN=choose-a-long-random-value
```

Prometheus can then read `/metrics`, using that value as a bearer token. A dashboard for Grafana is available as [grafana-dashboard.json](/install/grafana-dashboard.json).

## Traces

Set `OTEL_EXPORTER_OTLP_ENDPOINT` to the address of an OpenTelemetry collector. Without it, no traces are sent anywhere.
