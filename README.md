# Mediarr

Monorepo for Mediarr (mediarr.app).

```
apps/       deployable applications
packages/   shared code
deploy/     nginx configuration (host site and Compose container)
```

## Request flow

```
internet -> host nginx (80/443, TLS) -> 127.0.0.1:9851 -> nginx (Compose) -> services
```

Host nginx also serves other sites on this server, so Mediarr does not bind 80 or 443.

## Run

```sh
docker compose up -d
curl http://127.0.0.1:9851/health
```

## Install the nginx site (once, requires sudo)

```sh
sudo cp deploy/nginx/mediarr.app.conf /etc/nginx/sites-available/mediarr.app
sudo ln -s /etc/nginx/sites-available/mediarr.app /etc/nginx/sites-enabled/mediarr.app
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d mediarr.app -d www.mediarr.app
curl https://mediarr.app/health
```
