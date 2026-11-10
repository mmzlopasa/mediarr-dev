---
title: TV
---

# TV

There are three ways to see your photos on a TV:

- **Play on TV** sends the photo or video you are looking at to a Chromecast, an Apple TV or a DLNA TV, and the TV follows as you swipe.
- **TV mode** is a page made for the TV's own browser and its remote.
- **The DLNA server** lets a TV browse your albums by itself, with its own remote.

## Play on TV

Open a photo or a slideshow and choose **Play on TV** (the cast button). In the app, on a narrow phone, it is in the menu of more actions.

The TV shows the photo that is on your screen: swipe, and the TV changes with it. A slideshow plays on the TV as it plays on the phone. For a video, the bar at the bottom pauses, plays and seeks it on the TV. **Stop** ends it.

| | The Mediarr app (iPhone and Android) | The web |
| --- | --- | --- |
| Chromecast and Google TV | Yes | Chrome only, and only over HTTPS |
| Apple TV (AirPlay) | iPhone: videos with the AirPlay button, photos with Screen Mirroring | Safari: videos only |
| DLNA TVs (most Samsung, LG, Sony, Philips TVs) | Yes | No |

The TV and the phone must be on the same network.

### On plain HTTP

Mediarr works on `http://IP-of-the-server:9851`, and so does casting from the app. Chrome, however, allows Cast from a web page only on HTTPS, so on plain HTTP the web says so instead of offering it. Use the app, or put Mediarr behind HTTPS with a domain of your own.

### What the TV gets

The TV fetches the photo or video itself, so it gets an address of its own: `/api/tv/<token>/...`.

- The token works for **4 hours**, and only for the photos and videos you sent to the TV while casting. It opens nothing else: no other photo, no list, no details, no account.
- **Stop** ends the token at once, also for a TV that kept the address.
- A photo goes as a JPEG of how it looks after your edits, at most 4K, **without any metadata**: no location, no camera, no date.
- A video plays from the stream the server made (HLS), or, for a DLNA TV and for a video that is not converted yet, from its original with **the location removed**.
- Nothing from the trash or the Locked folder can be sent. Something that goes to the trash or the Locked folder while it is on the TV stops being available to it.
- The TV needs no password and gets no cookie.

### Finding a TV

The app looks for Chromecasts (mDNS) and DLNA TVs (SSDP). On an iPhone, Apple allows asking the whole network at once only to apps with a special entitlement, which a sideloaded app does not have, so the app asks each address of your network in turn; most TVs answer that too. If a TV is not found, choose **Add a TV by its address** and type its IP address, or the address of its UPnP description.

### AirPlay

On an iPhone, the AirPlay button in the list chooses an Apple TV. Videos you then play in Mediarr go to it. iOS does not let an app send a photo over AirPlay by itself: for photos, turn on **Screen Mirroring** in Control Centre, and the photo you are looking at is on the TV. In Safari on a Mac or iPad, a video can be sent with AirPlay; photos only with Screen Mirroring.

## TV mode

Open **TV mode** from the account menu, or go to `/tv` on the TV's browser. It shows one large photo from what you have chosen, and rows of memories, albums and people beneath it.

It is made for a remote:

- **Arrows** move between rows and along them.
- **OK** plays the chosen memory, album or person as a slideshow. In the slideshow, the arrows go back and forward and OK pauses.
- **Back** leaves the slideshow, and then TV mode.

TV mode needs the same sign-in as the rest of Mediarr, and works on plain `http://IP-of-the-server:9851` like everything else.

## DLNA server

Mediarr can show up on the TV as a media server, like a NAS, with your albums in it. It is **off**, and it stays off until you do both of these:

1. In `.env`, add `dlna` to `COMPOSE_PROFILES`, for example:

   ```
   COMPOSE_PROFILES=dlna
   ```

   or, with smart search, `COMPOSE_PROFILES=ml,dlna`. Then run `docker compose up -d`.

2. In **Administration → Settings → Server**, turn on **DLNA media server**. The app has the same switch.

The administrator who turns it on shares **their own albums**, and nobody else's. Anything on the home network can then see those albums without a password, which is how DLNA works; that is why it is off by default.

### Why a separate service

TVs find a media server by multicast on the home network, which does not leave Docker's own network. So `docker-compose.yml` has a small `dlna` service with `network_mode: host`. It only announces Mediarr and passes requests under `/dlna/` on to it; it has no access to the database or your files, and the rest of Mediarr is not reachable through it. The settings page says whether it is running.

It uses:

| Setting in `.env` | Default | What it is |
| --- | --- | --- |
| `DLNA_PORT` | `8200` | The port on the host where TVs fetch albums and photos. It must be free. |
| `DLNA_MEDIARR_URL` | `http://127.0.0.1:${HTTP_PORT}` | How the host reaches Mediarr. Change it only if `BIND_ADDRESS` is a single address other than `0.0.0.0` or `127.0.0.1`, e.g. `http://192.168.1.5:9851`. |

UDP port 1900 on the host must not be used by another DLNA server (such as MiniDLNA or Plex's DLNA).

Mediarr answers on `/dlna/` only to addresses of a home network (`10.x`, `172.16–31.x`, `192.168.x`, link-local and IPv6 ULA). If you have your own reverse proxy in front, requests coming through it from the internet are refused.

Photos go to the TV as JPEG without metadata, and videos as their originals without the location, as above. Photos in the trash or the Locked folder are never shown.
