---
title: Sign-in options
---

# Sign-in options

## Two-factor sign-in

Each person turns on an authenticator app under **Account**.

## Single sign-on (OIDC)

Under **Admin → Settings**, enter your provider's issuer, client ID and secret, and a label for the button.

Give your provider this redirect address:

```text
http://your-server-ip:9851/api/auth/oidc/callback
```

The mobile app signs in through the same address, so it needs nothing more.

People are matched by the email address, which the provider must have verified. Afterwards they are recognised by their identity at the provider, even if the email changes. Administrators are not linked by email unless you turn that on, which is less safe.

## Passkeys

Passkeys are added under **Account** on the web. Browsers allow them only over HTTPS with a domain name, or on `localhost`, so they are not available at an IP address.

## Who may connect

Under **Admin → Security** you can limit who reaches the server, which matters most when it is on the internet. Both are off by default.

- **Allowed addresses.** Only the listed addresses and networks, such as `192.168.1.0/24`, get any answer. The page shows the address the server sees for you, and refuses a list without it.
- **Device approval.** A new browser or phone can sign in only after an administrator approves it on that page. It adds to your password and two-factor sign-in and does not replace them, as whoever copies a device's data could copy its approval too.

Behind your own reverse proxy, set `TRUSTED_PROXY_HOPS` to the exact number of proxies. With too few, every visitor looks like the proxy. With too many, a visitor could claim any address, and the list would protect nothing.

The same page lists attempts to connect: sign-ins, failed passwords, lockouts and refused addresses and devices, with the time, address and device. They are kept for a year. Passwords are never recorded.

### If you lock yourself out

On the server, in the folder with your `docker-compose.yml`:

```bash
docker compose exec server /mediarr security reset
```

This turns both rules off, and takes effect within 10 seconds.
