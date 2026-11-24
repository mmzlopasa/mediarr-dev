---
title: Domain and HTTPS
---

# Domain and HTTPS

Mediarr works at an IP address with no domain, at `http://your-server-ip:9851`, and keeps working there. A domain and HTTPS are optional and up to you: to reach Mediarr from outside your home, put your own reverse proxy with HTTPS in front of it.

## What to expose

Expose only the port of Mediarr's nginx: `HTTP_PORT` in `.env`, 9851 by default. Never expose the database, the analysis service or Ollama. In `docker-compose.yml` they have no published port, and the database is on an internal network that only the server and worker reach. Keep it that way.

## 1. Change `.env`

When the proxy runs on the same computer as Mediarr:

```bash
BIND_ADDRESS=127.0.0.1
TRUSTED_PROXY_HOPS=1
```

`BIND_ADDRESS=127.0.0.1` makes port 9851 answer only on that computer, so nobody can go around the proxy. If the proxy runs on another computer, leave `BIND_ADDRESS` as it is and let only the proxy reach the port.

`TRUSTED_PROXY_HOPS` is the number of your own proxies in front of Mediarr; Mediarr's own nginx does not count. The server takes the visitor's address from `X-Forwarded-For`, counting that many entries from the right. It matters: without it every visitor looks like the proxy, and one person's failed sign-ins lock out everyone. Never set it higher than the real number, or a visitor could claim any address.

Apply it with `docker compose up -d`.

## 2. Configure the proxy

The proxy must:

- pass `X-Forwarded-For`, and `X-Forwarded-Proto https`. Only then does Mediarr know the visit is over HTTPS and mark its cookies `Secure`.
- pass WebSocket upgrades (the `Upgrade` and `Connection` headers).
- set no limit on the size of a request and not buffer uploads, and allow long timeouts, as a large video can take a long time to upload or download. Mediarr sets its own limit with `MAX_UPLOAD_MB`, and none by default.

With nginx:

```nginx
server {
    listen 443 ssl;
    server_name photos.example.com;

    # your certificate settings here

    client_max_body_size 0;
    proxy_request_buffering off;
    proxy_read_timeout 1h;
    proxy_send_timeout 1h;

    location / {
        proxy_pass http://127.0.0.1:9851;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

## Security headers

Mediarr already sends its own security headers: `Content-Security-Policy`, `X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options`, `Cross-Origin-Opener-Policy` and `Permissions-Policy`. Do not add other values for these in the proxy, as two policies can stop parts of the app from working.

Mediarr sends no `Strict-Transport-Security`, so that it keeps working on plain `http://`. Once HTTPS works on your domain, the proxy may add it there.

With HTTPS and a domain name, [passkeys](/administration/sign-in#passkeys) become available.
