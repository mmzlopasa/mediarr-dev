---
title: What's new
---

# What's new

The server and the web come as one version, such as `v0.2.40`. The apps have versions of their own, such as `app-v0.10.0`. To update the server, see [upgrading](/install/upgrading). The apps are at [cdn.mediarr.app/apps/mediarr.apk](https://cdn.mediarr.app/apps/mediarr.apk) and [mediarr.ipa](https://cdn.mediarr.app/apps/mediarr.ipa).

## Apps

### app-v0.10.2
- Backup keeps "only new photos" when albums change, waits instead of giving up when the server cannot be reached, retries failed files by itself, and waits for Wi-Fi for photos that are only in iCloud.
- On Android, backup asks for access to photo locations and never sends a copy without them. Keys are kept encrypted.
- The home screen widget shows its photo also on a tinted home screen, in your language, and is cleared when you sign out.
- A sign-in link from outside the app asks before signing in to a server.

### app-v0.10.1
- One tap on a photo hides the bars and the status bar, so the whole photo shows.
- On an iPhone, the widget screen checks the installation and says why the widget is not offered, when it is not.

### app-v0.10.0
Everything from the server versions up to v0.2.40: culling, smart memories, export, Play on TV, and the refined screens.

### app-v0.9.0
Everything up to v0.2.35: duplicates and Clean up, dates and places of many photos, signing in with a QR code, administration in the app, four languages, and private links.

## Server and web

### v0.2.42
- Private links: details such as the camera and the date are left out of what the visitor sees too, an edited photo is shared as edited, and a download limit also covers playing a video.
- Moving files with the storage template can never write over another original.
- Keys from the API need the admin permission for everything an administrator can do.
- The page for an error says what happened and offers to try again; the public link page too.
- Escape closes only the topmost window, and the photo viewer keeps the keyboard inside it.
- The trash shows the server's number of days instead of a fixed one.
- Copies for the TV are removed with their photo, an import no longer hangs on a server that stops answering, and the log no longer lists requests a browser left as errors.
- The service for smart search checks every model it downloads, and gets only its own settings.

### v0.2.41
- One tap on an open photo hides the bars and the arrows, so the whole photo shows; the next tap brings them back.
- docs.mediarr.app shows the new icon.

### v0.2.40
- The screens added lately were checked on phones and computers, light and dark, in all four languages, and refined.
- Fixed: the duplicates page asked the server without end; the selection bar and the TV menu went off a phone's screen; German and Slovenian showed English dates and counts.
- Opening search starts loading the model that reads words, so the first query after a quiet while does not wait for it.

### v0.2.39
- [Play on TV](/features/tv): Chromecast, AirPlay and DLNA, from the viewer and the slideshow.
- An optional DLNA server, so a TV can browse your albums by itself.

### v0.2.38
- [Export](/features/export) of a whole library: originals, sidecars, albums and all the details in one JSON.

### v0.2.37
- [Smart memories](/features/memories): trips, a person through the years, birthdays, the year in photos and a month ago. A memory can be hidden, and a person left out.

### v0.2.36
- [Culling a shoot](/features/library#culling-a-shoot): pick, reject, stars and side-by-side comparison.
- [Smart search](/features/smart-search) lets its models go after a quiet while, and can run on another computer with a token.
- Search on 100,000 photos answers in about 0.2 s instead of 0.7 s.

### v0.2.35
- [Private links](/features/sharing#privacy-of-a-public-link): faces blurred, camera details and the date taken out, the visitor's name asked, and a list of who opened a link.
- Sending a photo from the app without its location, camera details or faces.

### v0.2.34
- [Languages](/features/languages): English, Croatian, German and Slovenian on the web, in the app and in e-mails.

### v0.2.33
- Administration in the app, the server's name, the QR code opening the app from the phone's camera, and duplicate videos.

### v0.2.30 to v0.2.32
- [Signing in with a QR code](/features/mobile-app#sign-in-on-a-phone-with-a-qr-code), and finding the server on the home Wi-Fi.
- [Duplicates and Clean up](/features/clean-up).

### v0.2.29
- [Dates, time zones and places](/features/editing) of many photos at once, also from a GPX track.
