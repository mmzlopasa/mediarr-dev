---
title: API keys
---

# API keys

Scripts and other programs sign in with a key, made under **Account → API keys** on the web, or under **Library → API keys** in the app, and sent in the `X-Api-Key` header. Each key has its own rights: **Read**, **Upload**, **Change and delete**, and for an administrator **Administration**. A key can also expire after a number of days (**Expires in days**, optional).

The key is shown once, when it is made. Give a key only the rights it needs: a key cannot manage the account. **Revoke** ends a key, and changing the account's password revokes all of them.

The API is described in `open-api/openapi.yaml` in the source code.
