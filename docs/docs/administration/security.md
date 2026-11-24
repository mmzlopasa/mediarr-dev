---
title: Security
description: "What a Mediarr installation exposes, how to put it on the internet safely, and how to report a vulnerability."
---

# Security

## What is exposed

The install file publishes one port: nginx, on `HTTP_PORT` (default `9851`). Everything else stays inside Docker:

| Container | Reachable from |
| --- | --- |
| `nginx` | The network, on `BIND_ADDRESS:HTTP_PORT` |
| `server`, `worker` | Only through nginx |
| `db` | Only the server and the worker, on a network of its own with no way out |
| `ml`, `ollama` | Only the other containers. Neither publishes a port |

Do not publish another port, and do not change `ports:` in `docker-compose.yml`. Ports published by Docker bypass firewalls such as `ufw`, so `HTTP_PORT` itself should be reachable only from your home network, or from a reverse proxy on the same machine.

The containers run with as few rights as each needs: the server, the worker and the analysis service run as normal users, programs inside cannot gain privileges, nginx and the analysis service cannot change their own system files, and each container keeps at most 50 MB of logs.

## On the internet

Mediarr works on plain `http://address:9851` at home. To reach it from outside, use one of these:

- **A VPN**, such as WireGuard or Tailscale. Nothing is opened to the internet.
- **A reverse proxy with HTTPS** in front of it. See [Reverse proxy](/administration/reverse-proxy), and set `BIND_ADDRESS=127.0.0.1` when the proxy is on the same machine.

Over plain HTTP outside your home, passwords and photos can be read on the way. Passkeys need HTTPS; everything else works without it. The sign-in cookie is marked `Secure` when the request arrived over HTTPS, and is always `HttpOnly` and `SameSite=Lax`. A session lasts 30 days.

The server sends its own security headers on every answer, among them a Content-Security-Policy, `X-Frame-Options` and `Referrer-Policy`. A reverse proxy should pass them on unchanged. It sends no `Strict-Transport-Security`, because Mediarr must keep working on plain HTTP: add that on your proxy once HTTPS works.

## Signing in

- After 10 failed sign-ins for an account, or 50 from one address, within 15 minutes, further attempts are refused for a while.
- Two-factor sign-in and passkeys are set up by each user. See [Sign-in](/administration/sign-in).
- Under **Admin → Security** you can allow only some addresses and networks, and approve each new device before it can sign in. The page also lists recent sign-ins and refused attempts. If you lock yourself out, run `docker compose exec server /mediarr security reset` on the server.

## The vault

After 5 wrong PINs, the vault stays locked for 15 minutes. Each further 5 wrong PINs double the wait, up to 24 hours. An administrator can reset a user's vault with `docker compose exec server /mediarr user reset-vault their@email`.

## API keys

Each key has only the rights it is given:

| Scope | Allows |
| --- | --- |
| `read` | Reading the library |
| `upload` | Uploading |
| `write` | Changing and deleting |
| `admin` | Administration. Only an administrator can give it |

No key can change the account itself: its password, two-factor sign-in or other keys. See [API keys](/administration/api-keys).

## Shared links

A link to an album can have a password, an end date and a limit on downloads, and can forbid downloads altogether. By default a link hides where photos were taken and the camera they were taken with; it can also hide the date, blur faces and ask visitors for their name. After 10 wrong link passwords in 15 minutes, further attempts are refused for a while. See [Sharing](/features/sharing).

## Backups and updates

- Keep [backups](/administration/backup) on another disk or another server. They are encrypted with your backup password.
- [Upgrade](/install/upgrading) when a new version comes out. The server asks the public repository now and then whether there is one; `UPDATE_CHECK=off` in `.env` stops the check.
- The database password in `.env` should be long and random. While it is still the one from the example file, the server says so in its log at every start.

## Reporting a vulnerability

Please report it privately, through **Security → Report a vulnerability** on the [GitHub repository](https://github.com/mediarr-app/mediarr/security), and not in a public issue. Include what you found, how to reproduce it, and which version you run.
