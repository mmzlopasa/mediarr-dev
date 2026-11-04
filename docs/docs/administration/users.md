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
