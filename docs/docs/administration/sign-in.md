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
