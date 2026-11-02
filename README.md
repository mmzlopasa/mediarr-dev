# Mediarr


## Tok zahtjeva

```
kod korisnika:       preglednik -> IP-servera:9851 -> nginx (Compose) -> server
na našem serveru:    internet -> host nginx (80/443, TLS) -> 127.0.0.1:9851 -> nginx (Compose) -> server
```

## Instalacija

Korisniku trebaju samo `deploy/compose.yaml` i `deploy/.env.example`, kopiran kao `.env`:

```sh
docker compose up -d
```

Aplikacija se otvara na `http://IP-servera:9851`, bez domene. Domenu i HTTPS korisnik po želji rješava sam, vlastitim reverse proxyjem ispred. Direktoriji iz `UPLOAD_LOCATION` i `CACHE_LOCATION` moraju pripadati korisniku `PUID:PGID`. `--profile ml` uključuje ML servis.

## Razvoj i demo

```sh
make dev     # http://127.0.0.1:9852, javno https://demo.mediarr.app
make lint test e2e lighthouse
```

`demo.mediarr.app` servira dev stack, pa se promjene koda vide odmah. Zato dev stack ostaje upaljen; `make down` gasi i demo.

## Naš server (mediarr.app, privremeno)

```sh
make deploy
curl https://mediarr.app/health
```

## Host nginx siteovi (jednom, traži sudo)

```sh
sudo cp deploy/nginx/mediarr.app.conf /etc/nginx/sites-available/mediarr.app
sudo ln -s /etc/nginx/sites-available/mediarr.app /etc/nginx/sites-enabled/mediarr.app
sudo cp deploy/nginx/demo.mediarr.app.conf /etc/nginx/sites-available/demo.mediarr.app
sudo ln -s /etc/nginx/sites-available/demo.mediarr.app /etc/nginx/sites-enabled/demo.mediarr.app
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d mediarr.app -d www.mediarr.app
sudo certbot --nginx -d demo.mediarr.app
```
