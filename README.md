# Mediarr


## Tok zahtjeva

```
kod korisnika:       preglednik -> IP-servera:9851 -> nginx (Compose) -> server
mediarr.app:         internet -> host nginx (80/443, TLS) -> 127.0.0.1:9851 -> landing (statički)
demo.mediarr.app:    internet -> host nginx (80/443, TLS) -> 127.0.0.1:9852 -> dev stack
```

## Instalacija

Korisniku trebaju samo `deploy/compose.yaml` i `deploy/.env.example`, kopiran kao `.env`:

```sh
docker compose up -d
```

Aplikacija se otvara na `http://IP-servera:9851`, bez domene. Domenu i HTTPS korisnik po želji rješava sam, vlastitim reverse proxyjem ispred. Direktoriji iz `UPLOAD_LOCATION` i `CACHE_LOCATION` moraju pripadati korisniku `PUID:PGID`. `--profile ml` uključuje ML servis.

Zaboravljena lozinka ili izgubljen 2FA postavljaju se iz naredbene linije (lozinka se čita sa stdin, a 2FA se isključuje):

```sh
docker compose exec -T server /mediarr user upsert ime@primjer.hr "Ime" --admin
```

## Razvoj i demo

```sh
make dev     # http://127.0.0.1:9852, javno https://demo.mediarr.app
make lint test e2e lighthouse
```

`demo.mediarr.app` servira dev stack, pa se promjene koda vide odmah. Zato dev stack ostaje upaljen; `make down` gasi i demo.

## Landing (mediarr.app)

Statička stranica u `landing/`, odvojena od aplikacije. Koristi `dash.css` i fontove iz `web/src/lib/design/`.

```sh
make landing
curl https://mediarr.app/health
```

## Provjera produkcijskog imagea

```sh
make deploy   # gradi iz repoa, sluša na vrijednosti HTTP_PORT iz deploy/.env (9855)
```

## Host nginx siteovi (jednom, traži sudo)

```sh
sudo cp deploy/nginx/mediarr.app.conf /etc/nginx/sites-available/mediarr.app
sudo ln -s /etc/nginx/sites-available/mediarr.app /etc/nginx/sites-enabled/mediarr.app
sudo cp deploy/nginx/demo.mediarr.app.conf /etc/nginx/sites-available/demo.mediarr.app
sudo cp deploy/nginx/cdn.mediarr.app.conf /etc/nginx/sites-available/cdn.mediarr.app
sudo ln -s /etc/nginx/sites-available/cdn.mediarr.app /etc/nginx/sites-enabled/cdn.mediarr.app
sudo ln -s /etc/nginx/sites-available/demo.mediarr.app /etc/nginx/sites-enabled/demo.mediarr.app
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d mediarr.app -d www.mediarr.app
sudo certbot --nginx -d demo.mediarr.app
sudo certbot --nginx -d cdn.mediarr.app
```

## Licenca

Sva prava pridržana. Vidi `LICENSE`.
