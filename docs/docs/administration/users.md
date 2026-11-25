---
title: Users
---

# Users

Accounts are added under **Admin → Users**, with a password of at least 12 characters. How much space each may use is set under **Admin → Storage**, in **Quota in GB**; an empty field means no limit. In the app, both are under **Account → Administration → Users**. **Admin → Activity log** shows who did what.

## From the command line

Run these in the folder with your `docker-compose.yml`.

### Set a forgotten password

It makes the account if there is none. It also turns off two-factor sign-in, ends the account's sessions, and removes its API keys, passkeys and single sign-on links. It reads the new password from the input, so type it and press Enter:

```bash
docker compose exec -T server /mediarr user upsert you@example.com "Your Name" --admin
```

Leave out `--admin` for an account that is not an administrator.

### Reset a vault PIN

```bash
docker compose exec server /mediarr user reset-vault you@example.com
```

### Delete an account

This deletes the account with all its photos and files, and cannot be undone.

```bash
docker compose exec server /mediarr user delete you@example.com
```

## Email

Under **Admin → Settings → Email**, enter your own SMTP server. Mediarr then tells people when an album is shared with them, when one of their devices stops backing up and when a shared link is first opened, and **Forgot your password?** on the sign-in page sends a link for a new one.

The link needs **Address of this server**, such as `https://photos.example.com`. Without it no link is sent, as a link built from the visitor's request could lead to someone else's site. The link works once, for one hour. Setting a new password this way signs out every device and removes API keys and passkeys, and leaves two-factor sign-in on.
