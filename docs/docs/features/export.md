---
title: Leaving Mediarr (export)
---

# Leaving Mediarr: export your whole library

Your photos are yours. An export packs your whole library into ZIP files that any computer can open, with everything Mediarr knows about each photo, so you can take it to another program or keep it as a copy.

## Start an export

- **On the web:** open the account menu and choose **Export**, then **Export my library**.
- **In the app:** open **Account → Export my library**, then **Export my library**.
- **An administrator** can export the library of anyone: on the web under **Administration → Users → Export library**, or in the app under **Administration → Users** with the share button beside the person. The export then shows in that person's own list too, with who started it. The person and the administrator who started it can download it; other administrators only see that it runs.

The export is made on the server in the background. You can close the page or the app: it goes on, and if the server restarts it continues from the last finished part. **Cancel** stops it and removes what was made.

Before it starts, Mediarr checks that the server's cache folder (`CACHE_LOCATION`) has room for a full copy of your originals plus 1 GB. If not, it does not start and says so.

## Download it

When the export is ready, each part has its own download button. Parts can be downloaded for **7 days**, after which they are removed from the server. A download that breaks can go on where it stopped (the server answers `Range` requests, so a browser or a download manager can resume it, and the app does so itself).

## What is in it

The library comes in parts named `mediarr-export-YYYY-MM-DD-part-001.zip`, `-part-002.zip` and so on, each **at most 10 GB** (a single video larger than that gets a part of its own). The files are stored, not compressed, because photos and videos are compressed already.

**Unpack every part into the same folder.** Together they give:

```
originals/2024/07/IMG_1234.jpg        every photo and video, byte for byte as uploaded
originals/2024/07/IMG_1234.jpg.xmp    its XMP sidecar, when Mediarr made one
originals/2024/07/IMG_1234 (2).jpg    a second file with the same name that month
albums/Holiday/album.json             the files of an album
albums/Holiday/Day 1/album.json       an album inside another
mediarr-export.json                   everything Mediarr knows about the library
README.txt                            this layout, in short
```

- **Originals** are sorted by the month they were taken. They are exactly the files you uploaded: edits are not applied to them.
- **XMP sidecars** sit beside their photo as `name.ext.xmp`, the way darktable, digiKam and others read them. They hold the rating, pick or reject label, description, date and place you set, people's names and tags.
- **Albums** are folders with an `album.json` that lists the album's files as paths from the export folder, so no photo is in the export twice. Smart albums are listed with the photos they held at the time of the export.
- **Not included:** photos in the trash and in the Locked folder (move them out first if you want them), photos others added to an album you share (they are theirs), and files of an [external library](/features/external-library): those stay in your own folder, where they already are, and are only listed in the metadata with their path in that folder.

Passwords, keys, sessions, tokens and other people's data are never in an export.

## Reading `mediarr-export.json`

One JSON file, with one photo per line in `assets`:

```json
{
  "format": "mediarr-export",
  "version": 1,
  "exportedAt": "2026-11-09T10:00:00Z",
  "owner": { "name": "Ana", "email": "ana@example.com" },
  "people": [{ "id": "…", "name": "Marko", "birthDate": "1990-05-01", "hidden": false }],
  "tags": ["holiday"],
  "assets": [
    {
      "id": "…",
      "file": "originals/2024/07/IMG_1234.jpg",
      "sidecar": "originals/2024/07/IMG_1234.jpg.xmp",
      "originalName": "IMG_1234.jpg",
      "kind": "photo",
      "sha256": "…",
      "takenAt": "2024-07-01T08:00:00Z",
      "timeZoneOffsetMinutes": 120,
      "localDateTime": "2024-07-01T10:00:00",
      "latitude": 45.81, "longitude": 15.98,
      "place": { "city": "Zagreb", "country": "Croatia" },
      "description": "Sunset at the pier",
      "rating": 4,
      "pick": "picked",
      "favorite": true,
      "archived": false,
      "tags": ["holiday"],
      "faces": [{ "personId": "…", "person": "Marko", "box": { "x1": 0.25, "y1": 0.25, "x2": 0.5, "y2": 0.75 } }],
      "albums": ["…"],
      "edits": { "rotate": 90, "crop": { "x": 0.1, "y": 0, "width": 0.8, "height": 1 } }
    }
  ],
  "albums": [{ "id": "…", "title": "Holiday", "folder": "albums/Holiday", "parentId": null, "assets": ["…"] }]
}
```

- `file` is the path in the export; it is `null` for a file that was missing on the server's disk (`"missing": true`) or that is in an external library (`externalPath` then says where).
- `sha256` is the checksum of the original, to check the copy: `sha256sum originals/2024/07/IMG_1234.jpg`.
- `takenAt` is in UTC; `localDateTime` is the time on the camera's clock where it was taken.
- `pick` is `picked`, `rejected` or `null`.
- Face boxes go from 0 to 1 across and down the picture as Mediarr shows it (after rotation and crop). `box` is `null` when it could not be worked out.
- `edits` is the edit list Mediarr keeps instead of changing the original (rotation, crop, brightness, contrast, saturation, filter), or `null`.

For example, to copy one album's photos into a folder of their own on Linux or macOS:

```sh
jq -r '.files[]' "albums/Holiday/album.json" | xargs -I{} cp "{}" ~/Holiday/
```
