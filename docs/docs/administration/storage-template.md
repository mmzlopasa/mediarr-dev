---
title: Storage template
---

# Storage template

Originals are kept in `UPLOAD_LOCATION`, in a folder for each user. By default each user's folder is laid out by year and month, as `2024/07/0123456789abcdef-IMG_0042.jpg`. An administrator can choose another layout under **Administration → Storage → Storage template**, on the web or in the app under **Storage template**.

## Fields

| Field | Gives |
| --- | --- |
| `{{y}}`, `{{yy}}` | the year, `2024` or `24` |
| `{{MM}}`, `{{dd}}` | the month and day, `07` and `05` |
| `{{hh}}`, `{{mm}}` | the hour and minute, `14` and `30` |
| `{{filename}}` | the name the file came with, without the extension |
| `{{ext}}` | the extension, `jpg` |
| `{{camera}}` | the camera model, or `Unknown camera` |
| `{{album}}` | the first album it is in, or `No album` |
| `{{hash}}` | the start of its checksum, which no other file has |

The date is when the photo was taken, or when it came in if that is not known. A template is a path with `/` between folders, and its last part must contain `{{filename}}` or `{{hash}}`, for example:

```text
{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}.{{ext}}
{{album}}/{{filename}}.{{ext}}
```

While you type, the page shows where a few real files would go.

## What moves

A new file goes where the template says once it has been processed. Files already in the library stay where they are until you ask: **Dry run** says how many would move and shows some of them, without moving anything, and only then can **Move the files** move them. The files themselves are never changed, only where they are on the disk. If two files would have the same name, the second gets `-1`, `-2` and so on: nothing is ever written over. Folders left empty are removed.

Each user's own folder stays the top, so different users' files never mix. An [external library](/features/external-library) is never moved. **Back to the usual layout** makes new files go by year and month again; files already moved stay where they are.
