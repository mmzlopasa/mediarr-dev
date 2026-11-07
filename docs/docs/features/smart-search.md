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

The models download on first use, about 1 GB, and the service needs about 2 GB of memory. Progress is under **Admin → Settings**. Pictures you already have are analysed in the background.

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
