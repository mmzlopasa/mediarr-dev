# Contributing

## Getting started

```bash
make dev
```

This starts everything with hot reload at `http://127.0.0.1:9852`.

## Rules

- Change the API only in `open-api/openapi.yaml`, then run `make gen`.
- Every database migration has an up and a down, and is tested with `make seed-large`.
- Every feature has unit tests and at least one end-to-end test.
- Originals are read only. An edit is a list of steps in the database.
- Mediarr must work fully at `http://server-ip:9851`, without a domain or HTTPS.
- Nothing in the interface is made up: everything shown comes from the server.
- Commit messages follow Conventional Commits.

## Before a commit

```bash
make lint test
make e2e
```

## Documentation

The site in `docs/` is built with `make docs`.
