---
title: Library
---

# Library

## Uploading

Drop files on the page, or choose **Add**, on the web; in the app, choose photos under **Upload**. Each file shows its progress. A file that is in leaves the list by itself a moment later, and when all are done a short note says how many were uploaded and how many were already there. A file that failed stays in the list with the reason, until you choose **Clear failed**.

## Recently added

**Recently added** shows photos and videos by when they reached the server, newest first, not by when they were taken. What a backup or an import just brought, even from ten years ago, shows here at once. The days in it are the days things came in; each photo still has its own date in its details. Archived and deleted photos are not in it.

It is in the menu on the web, where it can be hidden like the other sections, and under **Library** in the app.

## JPEG XL

JPEG XL photos (`.jxl`) come in like any other: uploads, backup, imports and the external library. Every browser and phone shows them, as Mediarr makes the previews itself; the original stays as it is and can be downloaded.

## 360° panoramas

A photo marked as a 360° panorama, as phones and 360° cameras do (Google Camera, Samsung, Insta360, Ricoh Theta), has a **360°** mark on its tile. It opens as a panorama: drag to look around, and pinch or scroll to zoom. The **360°** button at the top shows it flat, as one picture, and back. Panoramas already in the library are found by themselves after the upgrade.

## Albums inside albums

An album can sit inside another, for example **Travels → 2024 → Japan**. On an album's page, **Album inside** makes a new one in it, and **Move to…** puts it inside another of your albums, or back at the top. The list of albums shows only the ones at the top, with how many albums are in each; a search finds them all. An album cannot go inside itself or an album that is in it.

Each album is shared on its own: someone who sees an album does not see the albums around it or inside it, and sees it at the top of their list. Deleting an album keeps the albums that were in it; they move to the top. In the app, the same is in the album's menu, and the albums inside show above its photos.

## Slideshow

**Slideshow** plays photos one after another, full screen. Start it from an album with the **Slideshow** button (in the app, in the album's menu), or from any open photo with ▶ at the top of the viewer: it goes from that photo in the order of the list it is in, such as the timeline, favourites, a person, a tag or a search.

Move the mouse or tap to show the controls; they hide again after a moment. On a computer, the space bar pauses, the arrows go back and on, **F** is full screen and **Esc** ends it; on a phone, swipe left and right. Under the cog choose the pace (3, 5, 10 or 20 seconds), the transition (crossfade, slide, slow zoom or none), shuffle, loop, and the date and place of each photo. The choices stay on that computer or phone. A video plays to its end, without sound. The screen does not sleep while it plays, and when the system asks for less motion, photos only fade.

## Culling a shoot

Cull goes through a shoot one photo at a time, with a strip of the others below. Start it from an album, from a day on the timeline, or from a selection. The next photos are loaded in advance, so moving on does not wait.

| Key | What it does |
| --- | --- |
| P | Pick, then the next photo |
| X | Reject, then the next photo |
| U | Remove the mark |
| 1 to 5 | Stars; the same number again removes them, as does 0 |
| Left and right arrows | Previous and next photo |
| Z | 100 % and back |
| C | Add the photo to a comparison, or take it out |
| Esc | End the comparison, then leave |

On a phone, drag a photo up to pick it, down to reject it and sideways to move on. Double tap zooms.

**Comparing** shows 2 to 4 photos side by side, and zooming or moving one does the same to the others.

When you are done, **Rejects to trash** moves the rejected photos to the trash after asking, and **Picks to new album** makes an album of the picked ones.

Only your own photos can be marked. The album and search filters offer picks, rejects and unmarked photos, and in a shared album they only look at your own photos, so nobody sees what you rejected. Marks are stored in the database and written to the XMP sidecar as `xmp:Label` (`Pick` or `Reject`). The original file is never changed.
