<p align="center">
  <img src="web/static/favicon.svg" width="96" alt="Mediarr">
</p>

<h1 align="center">Mediarr</h1>

<p align="center">A self-hosted photo and video library, with apps for iPhone and Android.</p>

<p align="center">
  <a href="https://docs.mediarr.app">Documentation</a> ·
  <a href="https://demo.mediarr.app">Demo</a> ·
  <a href="https://mediarr.app">Website</a>
</p>

## Features

| Feature | Web | Mobile |
| --- | --- | --- |
| Automatic background backup | | Yes |
| Timeline, albums, favourites, archive, trash | Yes | Yes |
| Locked vault | Yes | Yes |
| Smart search in plain language | Yes | Yes |
| People and face recognition | Yes | Yes |
| Map, places and trips | Yes | Yes |
| Memories | Yes | Yes |
| Partner sharing, shared albums, public links | Yes | Yes |
| Non-destructive editing | Yes | Yes |
| Duplicates and stacks | Yes | Yes |
| External libraries | Yes | Yes |
| Family library | Yes | Yes |
| AI descriptions with a local model | Yes | Yes |
| Import from Immich, Google Takeout, iCloud | Yes | |
| Encrypted backups, restore testing | Yes | |
| OIDC, two-factor sign-in, API keys | Yes | Yes |
| Passkeys, kiosk | Yes | |

## Install

```bash
mkdir -p ~/mediarr && cd ~/mediarr
curl -fsSL -o docker-compose.yml https://cdn.mediarr.app/install/docker-compose.yml
curl -fsSL -o .env https://cdn.mediarr.app/install/example.env
```

Edit `.env`, make the folders it names, then:

```bash
docker compose up -d
```

Mediarr opens at `http://your-server-ip:9851`. The [installation guide](https://docs.mediarr.app/install/docker-compose) has every step.

## Mobile apps

- [Android (.apk)](https://cdn.mediarr.app/apps/mediarr.apk)
- [iPhone (.ipa)](https://cdn.mediarr.app/apps/mediarr.ipa)

## Repository

| Folder | Contents |
| --- | --- |
| `server/` | API and background worker, in Go |
| `web/` | Web interface, in SvelteKit |
| `machine-learning/` | Search and face recognition service, in Python |
| `open-api/` | API definition |
| `docker/` | `docker-compose.yml` and `example.env` |

## License

All rights reserved. See [LICENSE](LICENSE).
