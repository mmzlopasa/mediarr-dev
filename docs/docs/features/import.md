---
title: Import
---

# Import

Bring in the photos you already have in Google Photos, iCloud or Immich. A file that is already in your library is not brought in again, so an import can be repeated, and nothing changes at the source.

## From Google Photos or iCloud

Anyone with an account can do this, without the administrator.

1. Ask for an export:
   - **Google Photos:** at [takeout.google.com](https://takeout.google.com), choose only **Google Photos** and download the ZIP files. A large library comes as several files.
   - **iCloud:** at [privacy.apple.com](https://privacy.apple.com), ask for a copy of your data, choose **iCloud Photos** and download the ZIP files.
2. In Mediarr on the web, open the account menu and choose **Import**.
3. Choose **Google Takeout** or **iCloud**, then choose **all** the ZIP files at once, as you downloaded them. Do not unpack them.
4. Choose **Upload**. If the upload is interrupted, choose the same files again and it goes on where it stopped.
5. When every file is in, choose **Bring in**.

Mediarr reads the ZIP files without unpacking them. A photo comes in with its date, place, description and favourite, and into the album it was in. Google writes these in a separate file, sometimes in another ZIP file than the photo, and Mediarr finds it there. Google gives the time without a time zone, so Mediarr works out the zone from where the photo was taken. Photos you had deleted at Google or Apple are left out.

The ZIP files are deleted once the import is done. An import that is stopped can go on later; its ZIP files are deleted if nobody comes back to it within a week.

The server needs free space for about twice the size of the export while it runs: once for the ZIP files, and once for the photos.

The mobile app shows your imports under **Account → Import**, with their progress and report, and can stop and continue them. Upload the ZIP files on a computer.

### What the report says

- **added:** new in your library.
- **already here or deleted:** the same file was already in your library, or it was deleted at the source.
- **failed:** the file could not be read. **Report** lists each one with the reason.

## From Immich

Under **Admin → Settings → Import**, choose **Immich**, enter the address of your Immich server and an API key from it, and choose whose library it goes into. Photos, favourites, archive, albums and people come across. Immich's locked folder is left out, so move those yourself if you want them.

## From a folder on the server

An administrator can also bring in an unpacked Takeout or iCloud export from a folder inside the [external library](/features/external-library): under **Admin → Settings → Import**, choose **Google Takeout** or **iCloud** and enter that folder.

The administrator sees every import there, whoever started it, with its report.

An import stops by itself if the server's disk is nearly full.
