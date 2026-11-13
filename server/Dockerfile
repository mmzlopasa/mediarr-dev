# Build context is the repository root, because the binary embeds web/.
FROM --platform=$BUILDPLATFORM node:22-slim AS web
WORKDIR /src/web
RUN npm install -g pnpm@12.16.1
COPY web/package.json web/pnpm-lock.yaml web/.npmrc ./
RUN pnpm install --frozen-lockfile --ignore-scripts
COPY web/ ./
RUN pnpm build

FROM --platform=$BUILDPLATFORM golang:1.27-alpine AS server
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src/server
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server/ ./
COPY --from=web /src/web/build/ ./internal/webui/dist/
ARG MEDIARR_VERSION=dev
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath \
    -ldflags="-s -w -X github.com/mediarr-app/mediarr/server/internal/app.Version=$MEDIARR_VERSION" -o /mediarr ./cmd/mediarr

FROM alpine:3.24
RUN apk add --no-cache vips-tools vips-heif vips-jxl exiftool ffmpeg libraw-tools font-dejavu restic postgresql17-client && adduser -D -u 10001 mediarr
COPY --from=server /mediarr /mediarr
USER 10001
EXPOSE 8080
ENTRYPOINT ["/mediarr"]
