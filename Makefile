export PATH := $(HOME)/.local/bin:$(PATH)
export DEV_UID := $(shell id -u)
export DEV_GID := $(shell id -g)

# Optional per-machine settings, such as DEV_LIBRARY on a separate disk.
-include docker/.env.dev
export DEV_LIBRARY DEV_MEDIA_CACHE DEV_MODELS

DEV_COMPOSE := docker compose -f docker/docker-compose.dev.yml
GO_TOOL := go tool -modfile=tools.mod
GENERATOR_IMAGE := openapitools/openapi-generator-cli:v7.17.0
PLAYWRIGHT_VERSION = $(shell cd web && node -p "require('@playwright/test/package.json').version")

.PHONY: dev down deploy landing docs testdata uploadtest seed-large clean-test-users bench gen web-build lint test e2e lighthouse

dev:
	mkdir -p .dev/cache .dev/web-node_modules .dev/library .dev/media-cache .dev/models .dev/external .dev/backup .dev/ollama
	$(DEV_COMPOSE) up -d --build --wait

down:
	$(DEV_COMPOSE) down

# Builds the production image from this checkout and runs it locally, to check it.
deploy:
	docker compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml up -d --build --wait

# Builds the documentation for docs.mediarr.app, and publishes the install files on cdn.mediarr.app.
docs:
	mkdir -p docs/static/install $(HOME)/mediarr-apps/install
	cp docs/monitoring/grafana-dashboard.json docs/static/install/
	cp docker/docker-compose.yml docker/example.env $(HOME)/mediarr-apps/install/
	cd docs && pnpm install --frozen-lockfile && pnpm build
	docker compose -f docker/docker-compose.docs.yml up -d --force-recreate --wait

# Publishes landing/ on mediarr.app.
landing:
	docker compose -f docker/docker-compose.landing.yml up -d --wait

TESTDATA ?= $(CURDIR)/.dev/testdata
SCALE ?= 5
JOBS ?= 2

testdata:
	mkdir -p "$(TESTDATA)"
	docker run --rm --user $(DEV_UID):$(DEV_GID) -e HOME=/tmp -e RAW_LIST=/scripts/raw-samples.txt -e JOBS=$(JOBS) \
		-v "$(CURDIR)/scripts:/scripts:ro" -v "$(TESTDATA):/out" mediarr-dev-go sh /scripts/testdata.sh /out $(SCALE)

# Uploads TESTDATA through the API twice and checks the upload gate.
uploadtest:
	@printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert uploadtest@example.com "Upload test"
	cd server && UPLOADTEST_PASSWORD=$(E2E_PASSWORD) go run ./cmd/uploadtest -dir "$(TESTDATA)" -email uploadtest@example.com

# Tests the newest migration going down and up on 100k assets, in a separate database.
seed-large: SHELL := /bin/bash
seed-large:
	$(DEV_COMPOSE) exec -T db psql -q -U mediarr -d postgres -c "DROP DATABASE IF EXISTS seed_large WITH (FORCE)" -c "CREATE DATABASE seed_large"
	$(DEV_COMPOSE) exec -T -e DATABASE_URL=postgres://mediarr:mediarr@db:5432/seed_large server /tmp/air/mediarr migrate
	$(DEV_COMPOSE) exec -T db psql -q -U mediarr -d seed_large < server/db/seed/large.sql
	time -p $(DEV_COMPOSE) exec -T -e DATABASE_URL=postgres://mediarr:mediarr@db:5432/seed_large server /tmp/air/mediarr migrate down
	$(DEV_COMPOSE) exec -T db psql -q -U mediarr -d seed_large -Atc "SELECT to_regclass('assets') IS NULL AS assets_removed"
	time -p $(DEV_COMPOSE) exec -T -e DATABASE_URL=postgres://mediarr:mediarr@db:5432/seed_large server /tmp/air/mediarr migrate
	$(DEV_COMPOSE) exec -T db psql -q -U mediarr -d postgres -c "DROP DATABASE seed_large WITH (FORCE)"

# Measures the timeline against the performance targets, on a temporary install.
bench:
	mkdir -p .dev
	BENCH_SKIP_FPS=$(BENCH_SKIP_FPS) scripts/bench.sh

gen:
	cd server && $(GO_TOOL) oapi-codegen -config oapi-codegen.yaml ../open-api/openapi.yaml
	cd server && $(GO_TOOL) sqlc generate
	cd web && pnpm exec openapi-typescript ../open-api/openapi.yaml -o src/lib/api/schema.d.ts
	docker run --rm --user $(DEV_UID):$(DEV_GID) -v "$(CURDIR):/repo" $(GENERATOR_IMAGE) generate \
		-g dart -i /repo/open-api/openapi.yaml -o /repo/mobile/packages/mediarr_api \
		--additional-properties=pubName=mediarr_api
	cd mobile/packages/mediarr_api && dart format .

web-build:
	cd web && pnpm build
	find server/internal/webui/dist -mindepth 1 ! -name .gitkeep -delete
	cp -r web/build/. server/internal/webui/dist/

lint:
	cd server && $(GO_TOOL) golangci-lint run ./...
	cd machine-learning && uv run ruff check . && uv run ruff format --check .
	cd web && pnpm lint && pnpm check
	cd mobile && flutter analyze --suppress-analytics

test:
	$(DEV_COMPOSE) exec -T server go test ./...
	cd machine-learning && uv run pytest
	cd web && pnpm test
	cd mobile && flutter test --suppress-analytics

# Runs in the Playwright image, so the host needs no browser or system libraries.
E2E_PASSWORD := $(shell openssl rand -hex 16)
E2E_EXTERNAL := $(if $(DEV_EXTERNAL),$(DEV_EXTERNAL),.dev/external)
e2e:
	# Hot reload can leave an old worker running next to the new one, and it would take jobs it does not know.
	$(DEV_COMPOSE) restart worker
	until $(DEV_COMPOSE) exec -T worker pgrep -f "mediarr worker" >/dev/null; do sleep 2; done
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-admin@example.com "Demo korisnik" --admin
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-user@example.com "Demo korisnik"
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-uploader@example.com "Demo korisnik"
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-owner@example.com "Demo korisnik"
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-member@example.com "Demo korisnik"
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-organizer@example.com "Demo korisnik"
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-stacker@example.com "Demo korisnik"
	printf '%s\n' "$(E2E_PASSWORD)" | $(DEV_COMPOSE) exec -T server /tmp/air/mediarr user upsert e2e-librarian@example.com "Demo korisnik"
	mkdir -p "$(E2E_EXTERNAL)/e2e-folder/inner"
	cp web/e2e/fixtures/gps.jpg "$(E2E_EXTERNAL)/e2e-folder/inner/external-photo.jpg"
	docker run --rm --network host --user $(DEV_UID):$(DEV_GID) -e HOME=/tmp -e E2E_PASSWORD=$(E2E_PASSWORD) \
		-v "$(CURDIR)/web:/web" -w /web mcr.microsoft.com/playwright:v$(PLAYWRIGHT_VERSION)-noble \
		node_modules/.bin/playwright test; status=$$?; rm -rf "$(E2E_EXTERNAL)/e2e-folder"; $(DEV_COMPOSE) exec -T worker sh -c 'rm -rf /backup/e2e-*'; $(MAKE) clean-test-users TEST_USERS="e2e-admin e2e-user e2e-uploader e2e-owner e2e-member e2e-organizer e2e-stacker e2e-librarian"; exit $$status

# Test accounts must not stay in the demo database, where they would appear as real data.
TEST_USERS ?= e2e-admin e2e-user e2e-uploader e2e-owner e2e-member e2e-organizer e2e-stacker e2e-librarian uploadtest
clean-test-users:
	for email in $(TEST_USERS); do \
		$(DEV_COMPOSE) exec -T server /tmp/air/mediarr user delete $$email@example.com; \
	done

lighthouse:
	docker run --rm --network host --user $(DEV_UID):$(DEV_GID) -e HOME=/tmp \
		-v "$(CURDIR)/web:/web" -w /web mcr.microsoft.com/playwright:v$(PLAYWRIGHT_VERSION)-noble \
		sh e2e/lighthouse.sh
