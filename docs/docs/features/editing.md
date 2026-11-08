---
title: Editing
---

# Editing

You can crop, rotate and adjust photos, and add filters when those are turned on. Originals are never changed: an edit is stored as a list of steps, so it can always be undone.

## Date, place and description

In a photo's details, **Edit details** changes when and where it was taken and adds a description. Find a place by name, or enter its coordinates. These are kept in the database, so the file itself never changes. **Use what the file says** goes back to the date and location in the file.

## Stars and XMP

Give a photo one to five stars in its details; choosing the same stars again takes them away. When a file has an XMP sidecar beside it, as `photo.jpg.xmp` or `photo.xmp` from Lightroom or darktable, Mediarr reads its date, place, stars and description, and what you set in Mediarr stays on top. **Download XMP** on the web gives a sidecar with all of it and the names of the people and tags, for other programs. Nothing is ever written next to or into an original.

## Tags

Select photos and choose **Tag** to give them a tag; open **Tags** to see every tag and its photos. On a tag's page, **Rename** gives it a new name, and the photos keep it. If another tag already has that name, Mediarr asks whether to join the two: the photos of both then carry one tag. In the app, the same is under **Library → Tags**, with the pencil at the top.

## Dates and time zones of many photos

Select photos in the library and choose **Date and time** (in the app, **More → Date and time…**). Before anything changes, a preview shows the first photos with their time before and after, and how many will change; **Save** applies it.

- **Shift**: earlier or later by days, hours and minutes, when a camera's clock was wrong. On the web, **This one was taken at…** takes the real time of the first selected photo and shifts all by the same.
- **Set a date**: one date for all, a minute apart so they keep their order, as for scanned photos.
- **Zone from the place**: photos with a location get the time zone of where they were taken, summer time included, and keep the hour on their clock.
- **A trip**: when a camera kept home's time abroad, say which zone its clock was on and where the photos were taken; they then show the hour it was there.
- **From the file**: dates set by hand go, and the file's own date comes back.

A new photo with a location but no time zone in its file gets the zone of its place by itself; a zone the file gives is never changed. Files are never changed: the corrections are kept beside them.

## Locations of many photos

Select photos and choose **Location** (in the app, **More → Location…**), again with a preview.

- **From nearby photos**: a photo without a location gets the place of the photo with one that was taken closest to it, within 30 minutes or as many as you choose, as when a camera without GPS is used beside a phone.
- **From a GPX track**: choose a track from a phone, watch or Garmin; photos without a location get the place where the track was when they were taken, between its two nearest points, if one is within 5 minutes. Get the dates right first.
- **Set a place**: find a place by its name, or type its latitude and longitude.
- **Take the location away**: it goes, and stays gone.
- **From the file**: locations set by hand go.
