---
title: Upgrading
---

# Upgrading

In the folder with your `docker-compose.yml`:

```bash
docker compose pull
docker compose up -d
```

The database is updated by itself when the server starts. To stay on one version, set `MEDIARR_VERSION` in `.env` to that number instead of `latest`.

## A snapshot before every upgrade

When a new version has to change the database, the server first keeps a snapshot of it, and only then changes it. Snapshots are in the library folder, under `.mediarr-snapshots` in `UPLOAD_LOCATION`. The last three are kept; older ones are removed by themselves. Administrators see them under **Administration → Health → Snapshots before upgrades**, and in the app under **Backup**, where they can also delete one.

An upgrade that does not change the database makes no snapshot.

If the disk has no room for the snapshot (about twice the size of the database), the server does not upgrade and says so in its log:

```bash
docker compose logs server
```

Free some space and run `docker compose up -d` again. To upgrade without a snapshot, at your own risk, set `MEDIARR_UPGRADE_SNAPSHOT=false` in `.env`.

A snapshot covers the database only. Your photos and videos are never changed by an upgrade. For the originals, keep a [backup](/administration/backup).

## Going back

If a new version does not work as it should:

```bash
docker compose stop server worker
docker compose run --rm server rollback
```

The command says which version and date it goes back to, and how many photos and videos were added since. Their files stay in the library, but the database will not know them, so upload them again afterwards. It asks before changing anything; add `--yes` to skip the question in a script. If anything fails, the database stays as it was.

Then set `MEDIARR_VERSION` in `.env` to the version it names, and start again:

```bash
docker compose up -d
```

To see all snapshots, or go back to an older one:

```bash
docker compose run --rm server rollback list
docker compose run --rm server rollback schema-36-to-37-20261107T120000Z
```

After going back, the version you left does not change the database again by itself: it stops and says why. A newer version upgrades as usual. To try the same version again on purpose:

```bash
docker compose run --rm server migrate
```
