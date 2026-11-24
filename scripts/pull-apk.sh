#!/bin/bash
# Signs the newest Android build from GitHub Actions and publishes it at
# https://cdn.mediarr.app/apps/mediarr.apk. Runs from cron. Does nothing when there is no new build.
# The signing key stays on this server: Android refuses an update signed with any other key.
# Whatever fails, the build already published stays as it is.
set -euo pipefail
umask 022

CHANNEL=${1:-}
if [ -z "$CHANNEL" ]; then
	status=0
	"$0" stable || status=$?
	"$0" dev || status=$?
	exit "$status"
fi
case "$CHANNEL" in
stable) SUFFIX= ;;
dev) SUFFIX=-dev ;;
*) echo "usage: $0 [stable|dev]" >&2; exit 2 ;;
esac

REPO=mmzlopasa/mediarr-dev
CHECK=$(cd "$(dirname "$0")" && pwd)/artifact.py
TOKEN_FILE=$HOME/.config/mediarr-gh-token
KEY_DIR=$HOME/.config/mediarr-android
TOOLS_DIR=$HOME/.local/share/mediarr-android
DEST_DIR=$HOME/mediarr-apps
DEST=$DEST_DIR/mediarr$SUFFIX.apk
STATE=$DEST_DIR/.apk$SUFFIX-run-id
ARTIFACT=Mediarr-apk$SUFFIX
PACKAGE=app.mediarr.mediarr
[ "$CHANNEL" = stable ] || PACKAGE=app.mediarr.mediarr.dev
# By digest, so the image that sees the signing key cannot change under this script.
JAVA_IMAGE=eclipse-temurin:21-jre@sha256:0b99b3376fbb50dbf9c0af8535fdd5b8eb0d3fdfc8b1e4967f383b6919f6901a
TOOLS_URL=https://dl.google.com/android/repository/build-tools_r34-linux.zip
APKSIGNER_SHA256=eefdd6aed9db9fb849e4c98a50d8741e19d1b674ba6547220bcb9c3ed152123a
# Far above any real build: the APK is about 120 MB.
MAX_BYTES=$((1024 * 1024 * 1024))

mkdir -p "$DEST_DIR"
exec 9>"$DEST_DIR/.pull-apk$SUFFIX.lock"
flock -n 9 || exit 0

# The token goes through stdin, so it never appears in the process list. curl does not send it on
# to the storage host a download is redirected to.
github() {
	printf 'header = "Authorization: Bearer %s"\n' "$(cat "$TOKEN_FILE")" |
		curl -K - -fsSL --proto '=https' --max-time "${2:-30}" --max-filesize "$MAX_BYTES" \
			-H 'Accept: application/vnd.github+json' "$1"
}

check() { python3 -I "$CHECK" "$@"; }

runs=$(github "https://api.github.com/repos/$REPO/actions/workflows/android.yml/runs?status=completed&per_page=30")
run_id=$(check run "$CHANNEL" android.yml <<<"$runs")
[ -n "$run_id" ] || exit 0
[ "$(cat "$STATE" 2>/dev/null || true)" != "$run_id" ] || exit 0

artifacts=$(github "https://api.github.com/repos/$REPO/actions/runs/$run_id/artifacts")
url=$(check artifact "$ARTIFACT" <<<"$artifacts")
[ -n "$url" ] || exit 0

work=$(mktemp -d "$DEST_DIR/.pull-apk-XXXXXX")
trap 'rm -rf "$work"' EXIT

# apksigner runs next to the signing key, so only the exact file checked here is used.
if [ ! -f "$TOOLS_DIR/apksigner.jar" ]; then
	mkdir -p "$TOOLS_DIR"
	curl -fsSL --proto '=https' --max-time 300 -o "$work/tools.zip" "$TOOLS_URL"
	unzip -qoj "$work/tools.zip" '*/lib/apksigner.jar' -d "$work"
	mv "$work/apksigner.jar" "$TOOLS_DIR/apksigner.jar"
fi
echo "$APKSIGNER_SHA256  $TOOLS_DIR/apksigner.jar" | sha256sum -c --quiet - ||
	{ echo "$TOOLS_DIR/apksigner.jar is not the expected apksigner" >&2; exit 1; }

# No network: nothing in the container needs one, and the key must not leave it. The password is
# read from a file inside, so it is never in a command line.
java_run() {
	local key_mode=$1
	shift
	docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/tmp \
		-v "$KEY_DIR:/key:$key_mode" -v "$TOOLS_DIR:/tools:ro" -v "$work:/work" "$JAVA_IMAGE" "$@"
}

if [ ! -f "$KEY_DIR/release.jks" ]; then
	mkdir -p "$KEY_DIR"
	chmod 700 "$KEY_DIR"
	(umask 077 && openssl rand -hex 24 >"$KEY_DIR/password")
	java_run rw keytool -genkeypair -keystore /key/release.jks -storepass:file /key/password \
		-alias mediarr -keyalg RSA -keysize 4096 -validity 36500 -dname "CN=Mediarr" >/dev/null 2>&1
	chmod 600 "$KEY_DIR/release.jks"
	echo "$(date -Is) created a new signing key in $KEY_DIR. Keep a copy of it safe."
fi

github "$url" 300 >"$work/artifact.zip"
check extract "$work/artifact.zip" mediarr-unsigned.apk "$work/mediarr-unsigned.apk" "$MAX_BYTES"
# Never sign anything but this app.
check apk "$work/mediarr-unsigned.apk" "$PACKAGE"
java_run ro java -jar /tools/apksigner.jar sign --ks /key/release.jks --ks-pass file:/key/password \
	--ks-key-alias mediarr --out /work/mediarr.apk /work/mediarr-unsigned.apk
# Never replace a working download with something that does not verify.
java_run ro java -jar /tools/apksigner.jar verify /work/mediarr.apk
check apk "$work/mediarr.apk" "$PACKAGE"

chmod 644 "$work/mediarr.apk"
# Same folder, so the switch is a rename: a download never gets half a file.
mv -f "$work/mediarr.apk" "$DEST"
printf '%s\n' "$run_id" >"$work/run-id"
mv -f "$work/run-id" "$STATE"
echo "$(date -Is) published the $CHANNEL Android build from run $run_id"
