<p align="center">
  <img src="design/banner.png" alt="Mediarr: your photos and videos, on your own server">
</p>

<p align="center">
  <a href="https://github.com/mediarr-app/mediarr/tags"><img src="https://img.shields.io/github/v/tag/mediarr-app/mediarr?label=version&color=ffd76a&labelColor=1b1530" alt="Version"></a>
  <a href="https://github.com/mediarr-app/mediarr/actions/workflows/ci.yml"><img src="https://github.com/mediarr-app/mediarr/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://docs.mediarr.app"><img src="https://img.shields.io/badge/docs-docs.mediarr.app-8b7cff?labelColor=1b1530" alt="Documentation"></a>
  <a href="https://demo.mediarr.app"><img src="https://img.shields.io/badge/demo-try_it_live-8b7cff?labelColor=1b1530" alt="Demo"></a>
</p>

<p align="center">
  <a href="https://mediarr.app">Website</a> ·
  <a href="https://docs.mediarr.app">Documentation</a> ·
  <a href="https://demo.mediarr.app">Live demo</a> ·
  <a href="#mobile-apps">Mobile apps</a>
</p>

---

**Mediarr** is a photo and video library that runs on your own server. Your phone backs up to it, you browse from a browser or the app, and every file stays on your own disk. No account with us, no subscription, and no outside service looking at your pictures.

## Try it first

Open [demo.mediarr.app](https://demo.mediarr.app) and sign in. The demo is read only.

| Email | Password |
| --- | --- |
| `demo@mediarr.app` | `mediarr-demo` |

## Install in five minutes

You need Linux and Docker Compose 2.23.1 or newer.

```bash
mkdir -p ~/mediarr && cd ~/mediarr
curl -fsSL -o docker-compose.yml https://cdn.mediarr.app/install/docker-compose.yml
curl -fsSL -o .env https://cdn.mediarr.app/install/example.env
```

In `.env`, set a database password and say where your files go. Make those folders, then start it:

```bash
docker compose up -d
```

Mediarr opens at `http://your-server-ip:9851`. It needs no domain name and no HTTPS, and you can add both whenever you like. The [installation guide](https://docs.mediarr.app/install/docker-compose) has every step.

## What it does

<table>
  <tr>
    <td width="33%"><img src="design/search.jpg" alt="Smart search"></td>
    <td width="33%"><img src="design/map.jpg" alt="Map"></td>
    <td width="33%"><img src="design/albums.jpg" alt="Albums"></td>
  </tr>
  <tr>
    <td align="center">Search in plain language</td>
    <td align="center">See where you have been</td>
    <td align="center">Keep and share albums</td>
  </tr>
</table>

| | Web | Mobile |
| --- | :-: | :-: |
| **Your library** | | |
| Automatic backup in the background | | ✓ |
| Timeline, albums, favourites, archive, trash | ✓ | ✓ |
| Locked vault with its own PIN | ✓ | ✓ |
| Non-destructive editing: originals are never changed | ✓ | ✓ |
| Duplicates and stacks of similar shots | ✓ | ✓ |
| Memories | ✓ | ✓ |
| **Finding things** | | |
| Smart search, in many languages, including text inside pictures | ✓ | ✓ |
| People, found by recognising faces on your server | ✓ | ✓ |
| Map, places and trips, worked out offline | ✓ | ✓ |
| AI descriptions with a local model | ✓ | ✓ |
| **Sharing** | | |
| Partners, shared albums and public links | ✓ | ✓ |
| Family library | ✓ | ✓ |
| Kiosk slideshow for a screen on the wall | ✓ | |
| **Running it** | | |
| External libraries, read only | ✓ | ✓ |
| Import from Immich, Google Takeout and iCloud | ✓ | |
| Encrypted backups, with a test that really restores them | ✓ | |
| Single sign-on, two-factor sign-in and API keys | ✓ | ✓ |
| Passkeys | ✓ | |
| Webhooks, Prometheus metrics and an activity log | ✓ | |

Smart search, faces and AI descriptions are optional. Everything else works without them.

## Your privacy

- Your files stay on your disk, and originals are read only.
- Search, faces, places and AI descriptions all run on your server.
- By default, the only outside request is for the map's background, from `cdn.mediarr.app`. You can change it in the settings.

## How much it needs

Measured on a small library:

| Part | Memory | Disk for the image |
| --- | --- | --- |
| Server, worker and database | About 300 MB | About 1.1 GB |
| Smart search and faces, optional | About 950 MB idle | 832 MB, and about 1 GB of models |
| AI descriptions, optional | About 8.8 GB while working | 8.5 GB, and the models |

## Mobile apps

| Platform | Download |
| --- | --- |
| Android | [mediarr.apk](https://cdn.mediarr.app/apps/mediarr.apk) |
| iPhone | [mediarr.ipa](https://cdn.mediarr.app/apps/mediarr.ipa), installed with a sideloading app such as Feather |

## Documentation

- [Requirements](https://docs.mediarr.app/install/requirements)
- [Install with Docker Compose](https://docs.mediarr.app/install/docker-compose)
- [Domain and HTTPS](https://docs.mediarr.app/administration/reverse-proxy)
- [Backup and restore](https://docs.mediarr.app/administration/backup)
- [FAQ](https://docs.mediarr.app/faq)

## In this repository

| Folder | Contents |
| --- | --- |
| [`server/`](server) | API and background worker, in Go |
| [`web/`](web) | Web interface, in SvelteKit |
| [`machine-learning/`](machine-learning) | Search and face recognition, in Python |
| [`open-api/`](open-api) | API definition |
| [`docker/`](docker) | `docker-compose.yml` and `example.env` |

## Security

Please report a vulnerability privately. See [SECURITY.md](SECURITY.md).

## License

Mediarr is free to install and run for your own use, from the official builds. The source code is public to read, but it is not open source: copying, changing or redistributing it needs written permission. See [LICENSE](LICENSE).

<p align="center"><br><b>Your memories belong to you.</b></p>
