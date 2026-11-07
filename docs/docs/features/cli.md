---
title: Command-line upload
---

# Command-line upload

`mediarr-cli` sends folders of photos and videos from a computer to your Mediarr server. It is one file with nothing to install, for Linux, macOS and Windows.

## Getting it

Download the one for your computer from `https://cdn.mediarr.app/install/cli/`:

| System | File |
| --- | --- |
| Linux, Intel or AMD | `mediarr-cli-linux-amd64` |
| Linux, ARM (Raspberry Pi) | `mediarr-cli-linux-arm64` |
| macOS, Apple silicon | `mediarr-cli-darwin-arm64` |
| macOS, Intel | `mediarr-cli-darwin-amd64` |
| Windows | `mediarr-cli-windows-amd64.exe` |

`SHA256SUMS` beside them lets you check the download. On Linux and macOS:

```bash
curl -fLo mediarr-cli https://cdn.mediarr.app/install/cli/mediarr-cli-linux-amd64
chmod +x mediarr-cli
```

On macOS, if it is refused the first time, allow it under **System Settings → Privacy & Security**.

## Signing in

Make an API key in Mediarr under **Account → API keys** with the **upload** right, and **read** and **write** too if you want to put files in an album. Then:

```bash
./mediarr-cli login http://192.168.1.10:9851
```

It asks for the key and keeps it in your user's settings folder, readable only by you. Instead, `MEDIARR_SERVER` and `MEDIARR_API_KEY` can be set, for scripts.

## Uploading

```bash
./mediarr-cli upload ~/Pictures
./mediarr-cli upload --album "Summer 2024" ~/Pictures/Hvar
./mediarr-cli upload --dry-run ~/Pictures
./mediarr-cli upload --delete-after ~/DCIM
```

It looks through the folders and the ones inside them (`--recursive=false` for only the top), and takes photos and videos, leaving other files and hidden folders alone. Before sending, it asks the server which files it already has, by their checksum, and sends only the rest, so running the same command twice sends nothing twice.

| Flag | Does |
| --- | --- |
| `--album NAME` | puts the files in this album, made if it does not exist |
| `--dry-run` | only says what would be sent |
| `--delete-after` | deletes each local file once the server has confirmed it, by its checksum |
| `--jobs N` | files sent at the same time, 3 by default |
| `--recursive=false` | only the folders given, not the ones inside them |

Large files go in parts. If the connection drops, it goes on from where the server has the file; if the whole command was stopped, run it again and it continues with what is left. The server checks each file's checksum and refuses a damaged one. `--delete-after` deletes only files the server has exactly, and never one that changed after it was sent.
