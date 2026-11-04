---
title: Domain and HTTPS
---

# Domain and HTTPS

Mediarr works at an IP address with no domain. To reach it from outside your home, put your own reverse proxy with HTTPS in front of it.

## 1. Change `.env`

```bash
BIND_ADDRESS=127.0.0.1
TRUSTED_PROXY_HOPS=1
```

`TRUSTED_PROXY_HOPS` matters: without it every visitor looks like the same person, and one person's failed sign-ins lock out everyone.

Apply it with `docker compose up -d`.

## 2. Configure the proxy

The proxy must allow large uploads, not buffer them, and pass WebSocket upgrades. With nginx:

```nginx
server {
    listen 443 ssl;
    server_name photos.example.com;

    # your certificate settings here

    client_max_body_size 0;
    proxy_request_buffering off;
    proxy_read_timeout 1h;

    location / {
        proxy_pass http://127.0.0.1:9851;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

With HTTPS and a domain name, [passkeys](/administration/sign-in#passkeys) become available.
