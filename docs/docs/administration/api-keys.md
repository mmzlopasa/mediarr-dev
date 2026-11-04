---
title: API keys
---

# API keys

Scripts and other programs sign in with a key, made under **Account**, and sent in the `X-Api-Key` header. Each key has its own rights: `read`, `upload`, `write` and `admin`.

Give a key only the rights it needs. Keys stop working when the account's password is changed.

The API is described in `open-api/openapi.yaml` in the source code.
