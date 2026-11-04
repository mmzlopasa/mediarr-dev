---
title: AI descriptions
---

# AI descriptions

A local model writes a short description of each photo, which makes it searchable, and lets you ask questions about your library. It runs through [Ollama](https://ollama.com) on your server, so your photos never leave it.

## Turning it on

1. Add the profile to `.env`, together with `ml` if you use it:

   ```bash
   COMPOSE_PROFILES=ml,ai
   ```

2. Apply it:

   ```bash
   docker compose up -d
   ```

3. Under **Admin → Settings → AI descriptions and questions**, set the address to `http://ollama:11434`.

The models take about 3 GB of disk and download by themselves.

:::warning Processor use
Without a graphics card, each photo takes a while and Ollama uses every processor core while it works. On a server shared with other services, those will slow down, especially after a large upload.
:::
