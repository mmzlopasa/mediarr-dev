---
title: Mobile app
---

# Mobile app

The app shows your library and backs up your phone in the background.

| Platform | Download |
| --- | --- |
| Android | [mediarr.apk](https://cdn.mediarr.app/apps/mediarr.apk) |
| iPhone | [mediarr.ipa](https://cdn.mediarr.app/apps/mediarr.ipa), installed with a sideloading app such as Feather |

## Signing in

Enter your server's address, such as `http://192.168.1.20:9851`, and your account. The phone must be able to reach that address.

## Backup

Choose which albums go to the server under **Backup** in the app. Uploads continue where they stopped after a lost connection, and files already on the server are not sent again.

Administration, imports and the kiosk are only on the web.

## Originals by default

Photos open at full size and videos play from the original file, on the web and in the app. When a device cannot play an original video, such as HEVC in some browsers, the converted version plays instead. Both can be turned off in the settings, to use less data.

## Sending and saving photos

Tap **Share** on a photo, or select several and tap **Share**, then choose:

- **Original**: the file as it is, with everything in it.
- **Smaller, for messages**: a JPEG of at most 2048 px, without the location. Quicker over mobile data.
- **Save to this phone**: the original, into the phone's own gallery.

Mediarr remembers the choice between original and smaller. A photo with edits is sent as it looks. A photo from the vault asks first, as it leaves the protected place.

The web app on a phone has the same **Share** button. On a computer, use **Download**.
