# Go toolchain plus the media tools the worker runs.
FROM golang:1.27-alpine
RUN apk add --no-cache vips-tools vips-heif exiftool ffmpeg libheif-tools libraw-tools curl font-dejavu restic postgresql17-client
