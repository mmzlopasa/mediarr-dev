# Mediarr


## Tok zahtjeva

```
internet -> host nginx (80/443, TLS) -> 127.0.0.1:9851 -> nginx (Compose) -> server
```

## Razvoj

```sh
make dev     # http://127.0.0.1:9852
make lint test e2e
make down
```

## Produkcija

Jednom, u `deploy/`: kopiraj `.env.example` u `.env` i upiši vrijednosti. Direktoriji iz `UPLOAD_LOCATION` i `CACHE_LOCATION` moraju pripadati korisniku `PUID:PGID`.

```sh
docker compose -f deploy/compose.yaml up -d --build --wait
curl http://127.0.0.1:9851/health
```

## Host nginx site (jednom, traži sudo)

```sh
sudo cp deploy/nginx/mediarr.app.conf /etc/nginx/sites-available/mediarr.app
sudo ln -s /etc/nginx/sites-available/mediarr.app /etc/nginx/sites-enabled/mediarr.app
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d mediarr.app -d www.mediarr.app
```
