---
title: "Mediarr app for iPhone and Android: backup and library"
sidebar_label: Mobile app
description: "The Mediarr app backs up your iPhone or Android phone to your own server in the background, and shows the whole library, also offline."
---

# Mobile app

The app shows your library and backs up your phone in the background.

| Platform | Download |
| --- | --- |
| Android | [mediarr.apk](https://cdn.mediarr.app/apps/mediarr.apk) |
| iPhone | [mediarr.ipa](https://cdn.mediarr.app/apps/mediarr.ipa), installed with a sideloading app such as Feather |

## Signing in

Enter your server's address, such as `http://192.168.1.20:9851`, and your account. The phone must be able to reach that address.

### Finding the server

On the sign-in screen the app looks for Mediarr servers on the Wi-Fi the phone is on and lists them under **On this network**, with the name the administrator gave the server (**Administration → Server settings → The server's name**). Tap one to fill in its address. The app asks each address of the network on port 9851, which works with the standard `docker-compose.yml`, and also listens for servers that announce themselves over mDNS (`_mediarr._tcp`), which needs the server container on the host network. iPhone asks once for permission to use the local network.

An administrator can turn this off under **Administration → Server → Apps on the same network can find this server**, or in the app under **Settings → Networking**. Finding a server never signs anyone in.

### Sign in on a phone with a QR code

Without typing a password on the phone:

1. Where you are already signed in, on the web or in the app, open the account menu and choose **Sign in on a phone** (in the app, **Sign in on another device**). A QR code and an eight-character code appear. They work once and for five minutes.
2. In the app on the new phone, tap **Scan QR code** on the sign-in screen and point the camera at the code. Scanning it with the phone's own camera app opens Mediarr and does the same. Or tap **Enter a sign-in code** and type it, after the server's address.
3. The screen with the code asks **Allow sign-in on (phone)?** Choose **Allow** only if it is your phone. A photo of the code alone gives nobody access.

The new phone shows under **Account → Devices**, where it can be signed out, and the security log records the sign-in. It also works for accounts that sign in only with single sign-on or a passkey. If you opened the web on the server itself (`localhost`), type the address the phone reaches into the dialog, so the QR code carries that address.

## Backup

Choose which albums go to the server under **Backup** in the app. Uploads continue where they stopped after a lost connection, and files already on the server are not sent again.

Administration, imports and the kiosk are only on the web.

## Backup devices

**Backup devices** (in the account menu on the web and in the app) lists every phone that backs up, with:

- how many of its files the **server** confirms, counted from the server's own files by their SHA-256, not from what the phone says;
- how many are still waiting or could not be sent, as the phone counts them;
- files the phone sent that are now in the trash or no longer on the server;
- when the phone last reported.

**What is missing** lists the files that could not be sent and the reason, and the ones no longer on the server. In the app, **Try again** sends the failed ones again.

The phone reports at most once an hour while backup runs, also when there is nothing new to send, and gives the server its list of confirmed files whenever the app is opened. If a phone does not report for 3 days, it is marked **Quiet**, and you get a notification here and in the app, and an e-mail if the administrator set up e-mail. You are told once per silence. Choose 1, 3, 7 or 14 days, or never, under **Warn me after**.

**Remove** takes an old phone off the list. Its photos stay on the server. Administrators see every user's devices under **Administration → Backup devices**, and in the app under **All backup devices**.

## Originals by default

Photos open at full size and videos play from the original file, on the web and in the app. When a device cannot play an original video, such as HEVC in some browsers, the converted version plays instead. Both can be turned off in the settings, to use less data.

## Sending and saving photos

Tap **Share** on a photo, or select several and tap **Share**, then choose:

- **Original**: the file as it is, with everything in it.
- **Smaller, for messages**: a JPEG of at most 2048 px, without the location. Quicker over mobile data.
- **Save to this phone**: the original, into the phone's own gallery.

Mediarr remembers the choice between original and smaller. A photo with edits is sent as it looks. A photo from the vault asks first, as it leaves the protected place.

The web app on a phone has the same **Share** button. On a computer, use **Download**.

## Home screen widget

The widget shows a photo from an album you choose, a different one every hour, also without a connection. Choose the album in the app under **Settings → Home screen widget**; the app makes a key for the widget that can only read. Then touch and hold an empty spot on the home screen and add the **Mediarr** widget: on an iPhone with **+** or **Edit → Add Widget**, on Android under **Widgets**. Tapping it opens Mediarr. **Turn off** in the same place empties it and revokes its key.

On an iPhone the widget fetches its photos itself. It needs the app and the widget to share a keychain group, which the certificate Feather signs with allows; if it does not, the app says so when you choose an album.

If the iPhone does not offer the widget at all, look at **Installation check** at the top of the same screen. It says whether the signing left the widget out, left it unsigned, or signed it with a profile that does not allow its identifier, and what to change in Feather.

## Administration

Administrators find **Administration** in the account menu of the app, with what the web has:

- **Overview**: users, photos and videos, what is processing or failed, disk, versions.
- **Users**: the list with storage used, adding a user, and quotas.
- **Server settings**: every setting from the web, including the server's name and whether apps on the network can find it.
- **Email**: the mail server and a test message.
- **Security**: single sign-on, device approval and allowed addresses, and attempts to get in.
- **Jobs**: each queue, pausing and resuming it, and failed jobs with **Try again**.
- **Audit log**: who changed what.

Backup, all backup devices and the storage template are there too.
