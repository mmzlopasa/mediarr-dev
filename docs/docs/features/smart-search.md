---
title: Smart search and faces
---

# Smart search and faces

Both run on a separate, optional service. Without it, everything else works.

## Turning it on

Add these to `.env`:

```bash
COMPOSE_PROFILES=ml
ML_URL=http://ml:8000
```

Then apply it:

```bash
docker compose up -d
```

The models download on first use, about 1 GB. Progress is under **Admin → Settings**. Pictures you already have are analysed in the background.

## Memory

The service opens a model when it first needs one, and closes it after 5 minutes without use. With nothing open it uses about 100 MB, and up to about 2 GB while every model is working. The first search after a quiet period takes a few seconds longer.

`ML_IDLE_MINUTES` changes the 5 minutes, and `0` keeps models open once they are loaded.

## On another computer

Analysis can run on a stronger computer in your home. On that computer, make a folder with these two files.

`docker-compose.yml`:

```yaml
services:
  ml:
    image: ghcr.io/mediarr-app/mediarr-ml:${MEDIARR_VERSION:-latest}
    env_file: .env
    ports:
      - "8000:8000"
    volumes:
      - model-cache:/models
    restart: unless-stopped

volumes:
  model-cache:
```

`.env`:

```bash
MEDIARR_VERSION=latest
ML_IDLE_MINUTES=5
ML_TOKEN=a-long-random-value
```

Start it with `docker compose up -d`, using the same version as your Mediarr server. Then, in the `.env` of your Mediarr server, leave `ml` out of `COMPOSE_PROFILES`, put in the address of the other computer, and apply it with `docker compose up -d`:

```bash
ML_URL=http://192.168.1.50:8000
ML_TOKEN=a-long-random-value
```

Set the same `ML_TOKEN` in the `.env` on the other computer. If they differ, **Admin → Health** says so; smart search then falls back to plain search and analysis waits.

If the other computer is switched off, analysis waits and continues when it is back. Search carries on with words on pictures and file names, and says so.

Your photos travel to that computer unencrypted, so use this only on a network you trust, or over a VPN. Do not open the port to the internet.

## Searching

Describe what you are looking for, in your own language. You can also filter by date, person, place and camera, and words inside pictures are found too.

## Filters

Choose **Filters** beside the search to narrow it, with words or without any:

- **Date**, from and to.
- **People**: everyone chosen together on the picture, or any of them.
- **Place**, **camera** and **lens**, from what your library has.
- **Type**: photos or videos.
- **Rating**: at least so many stars.
- **Tags**: every one chosen.
- **Album**: only in one album, or in no album at all.
- **Favourites only**.

The filters in a search show as chips under it. What Mediarr found in your words, such as a name, a place or a year, shows as an outlined chip: take it away and that word is searched as a word. In an album, **Search in album** searches only that album, also one shared with you.

The web app keeps the filters in the address, so a search can be bookmarked or sent.

## People

Faces are grouped into people, and you can name, merge and hide them. Names and faces stay private: partners, album members and guests do not see them, and nothing about faces leaves your server.

`ML_FACE_MODEL` chooses the model: `buffalo_l` by default, or `buffalo_s` for weaker hardware.

:::note License
The default face models are licensed for non-commercial use only. Check their terms if you use Mediarr commercially.
:::

## Correcting faces

In a photo's details, each face has its own row. Choose who it is, give it a new name, or say **Not a person**. Your answer stays when the photo is analysed again. A person's page also keeps their date of birth.
