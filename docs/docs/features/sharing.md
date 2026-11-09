---
title: Sharing
---

# Sharing

- **Partners** see your library, and you can choose to see theirs on your timeline.
- **Shared albums** have members, who are viewers, contributors who can add photos, or editors who can also change the album.
- **Public links** need no account. They can have a password and an expiry date, and can hide the location, faces and camera details. They also show who opened them (see below).
- **Family library** is a shared space for chosen accounts, turned on under **Admin → Settings**.

If you have edited a photo, others see only the edited version. They do not get the original, its Live Photo video or what you cropped out.

## Privacy of a public link

When you make a link to an album, on the web or in the app, you choose what it leaves out. You can change it later, and it applies at once.

- **Hide faces.** Choose **All faces** or **All but chosen people**, for example to show only your family. Faces are blurred in every picture on the link and in what is downloaded. The original is never available through such a link: a download is a blurred copy in full size. Only faces Mediarr has found are blurred. The option says how many photos have not been checked for faces yet. Videos show only as a still and do not play.
- **Remove camera details** (on for new links). Downloads leave out the camera, lens, serial numbers, author and software.
- **Remove the date too.**
- **Location.** It stays hidden unless you choose to show it.
- **Ask for a name.** The visitor types their name before seeing the album.

After you make a link, **Preview as a visitor** shows exactly what others see. Your own visits are not counted.

### Who opened it

Each link shows how often it was opened, and **Who opened it** lists each visit:

- when it happened, and the name if the link asked for one;
- the rough place (city and country), and the kind of device and browser;
- how many photos were viewed and downloaded.

The address a visit came from is not stored. The first time a link is opened, you get a notification, and an e-mail if e-mail is set up. Visits are kept for 90 days.

Places come from DB-IP Lite ([db-ip.com](https://db-ip.com), CC BY 4.0). Mediarr downloads that list (about 60 MB) the first time a link is opened, and once a month after that. With `UPDATE_CHECK=off` in `.env` it never downloads it, and visits show no place.

## Sending a photo to another app

When you share a photo from the app to another app, such as a message, you choose what goes with it:

- **Remove location** (on by default);
- **Remove camera details** (on by default);
- **Hide faces**.

Mediarr then sends a copy without what you chose to remove. The original stays as it is.

## Notifications

The bell at the top, on the web and in the app, tells you when an album was shared with you, when one of your links was opened for the first time, and how an import you started ended. Administrators are also told when a backup fails. Read notifications are removed after 90 days.
