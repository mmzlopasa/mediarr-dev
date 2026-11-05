---
title: Users
---

# Users

Accounts are managed under **Admin → Users**, including how much space each may use. **Admin → Activity log** shows who did what.

## From the command line

Run these in the folder with your `docker-compose.yml`.

### Set a forgotten password

This also turns off two-factor sign-in and ends the account's sessions and keys. It reads the new password from the input, so type it and press Enter, then Ctrl+D:

```bash
docker compose exec -T server /mediarr user upsert you@example.com "Your Name" --admin
```

Leave out `--admin` for an account that is not an administrator.

### Reset a vault PIN

```bash
docker compose exec server /mediarr user reset-vault you@example.com
```

### Delete an account

```bash
docker compose exec server /mediarr user delete you@example.com
```

## Email

Under **Admin → Settings → Email**, enter your own SMTP server. Mediarr then tells people when an album is shared with them, and **Forgot your password?** on the sign-in page sends a link for a new one.

The link needs **Address of this server**, such as `https://photos.example.com`. Without it no link is sent, as a link built from the visitor's request could lead to someone else's site. Setting a new password this way signs out every device and removes API keys and passkeys, and leaves two-factor sign-in on.
