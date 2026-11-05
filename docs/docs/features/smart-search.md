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

## People

Faces are grouped into people, and you can name, merge and hide them. Names and faces stay private: partners, album members and guests do not see them, and nothing about faces leaves your server.

`ML_FACE_MODEL` chooses the model: `buffalo_l` by default, or `buffalo_s` for weaker hardware.

:::note License
The default face models are licensed for non-commercial use only. Check their terms if you use Mediarr commercially.
:::

## Correcting faces

In a photo's details, each face has its own row. Choose who it is, give it a new name, or say **Not a person**. Your answer stays when the photo is analysed again. A person's page also keeps their date of birth.
