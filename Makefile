export PATH := $(HOME)/.local/bin:$(PATH)
export DEV_UID := $(shell id -u)
export DEV_GID := $(shell id -g)

DEV_COMPOSE := docker compose -f deploy/compose.dev.yaml
GO_TOOL := go tool -modfile=tools.mod
GENERATOR_IMAGE := openapitools/openapi-generator-cli:v7.17.0
PLAYWRIGHT_VERSION = $(shell cd web && node -p "require('@playwright/test/package.json').version")

.PHONY: dev down deploy gen web-build lint test e2e lighthouse

dev:
	mkdir -p .dev/cache .dev/web-node_modules
	$(DEV_COMPOSE) up -d --wait

down:
	$(DEV_COMPOSE) down

# Builds production (mediarr.app) from this checkout.
deploy:
	docker compose -f deploy/compose.yaml -f deploy/compose.build.yaml up -d --build --wait

gen:
	cd server && $(GO_TOOL) oapi-codegen -config oapi-codegen.yaml ../api/openapi.yaml
	cd server && $(GO_TOOL) sqlc generate
	cd web && pnpm exec openapi-typescript ../api/openapi.yaml -o src/lib/api/schema.d.ts
	docker run --rm --user $(DEV_UID):$(DEV_GID) -v "$(CURDIR):/repo" $(GENERATOR_IMAGE) generate \
		-g dart -i /repo/api/openapi.yaml -o /repo/mobile/packages/mediarr_api \
		--additional-properties=pubName=mediarr_api
	cd mobile/packages/mediarr_api && dart format .

web-build:
	cd web && pnpm build
	find server/internal/webui/dist -mindepth 1 ! -name .gitkeep -delete
	cp -r web/build/. server/internal/webui/dist/

lint:
	cd server && $(GO_TOOL) golangci-lint run ./...
	cd ml && uv run ruff check . && uv run ruff format --check .
	cd web && pnpm lint && pnpm check
	cd mobile && flutter analyze --suppress-analytics

test:
	cd server && go test ./...
	cd ml && uv run pytest
	cd web && pnpm test
	cd mobile && flutter test --suppress-analytics

# Runs in the Playwright image, so the host needs no browser or system libraries.
e2e:
	docker run --rm --network host --user $(DEV_UID):$(DEV_GID) -e HOME=/tmp \
		-v "$(CURDIR)/web:/web" -w /web mcr.microsoft.com/playwright:v$(PLAYWRIGHT_VERSION)-noble \
		node_modules/.bin/playwright test

lighthouse:
	docker run --rm --network host --user $(DEV_UID):$(DEV_GID) -e HOME=/tmp \
		-v "$(CURDIR)/web:/web" -w /web mcr.microsoft.com/playwright:v$(PLAYWRIGHT_VERSION)-noble \
		sh e2e/lighthouse.sh
