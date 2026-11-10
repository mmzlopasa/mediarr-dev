---
title: Requirements
---

# Requirements

## Software

- Linux, with [Docker Engine](https://docs.docker.com/engine/install/).
- Docker Compose **2.23.1 or newer**. Older versions cannot read the file. Check with `docker compose version`.

Mediarr is built and tested on Linux with x86-64 processors.

## Memory

| What runs | Memory needed |
| --- | --- |
| Mediarr itself | The server aims to stay under 300 MB when idle, plus the database |
| Smart search and faces | About 2 GB more while it works. The models leave memory after 5 minutes without work, and the service then needs about 100 MB |
| AI descriptions | About 8.8 GB while working, measured with the default models |

## Disk

Mediarr keeps three kinds of data, and each can be on a different disk:

| Setting | What it holds | Advice |
| --- | --- | --- |
| `UPLOAD_LOCATION` | Your original files | As big as your library. A second disk, USB drive or network share all work |
| `CACHE_LOCATION` | Thumbnails and video versions | Can always be made again. A fast disk helps |
| `DB_LOCATION` | The database | **Must be a local disk.** Databases can be corrupted on network shares |

## Processor

Everything runs without a graphics card. Hardware video encoding (`VIDEO_ACCEL`) is optional. Without a graphics card, analysing a large library and writing AI descriptions take a long time and use the processor heavily, so on a shared server plan for that.
