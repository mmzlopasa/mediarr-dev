#!/bin/bash
# Signs the newest successful Android build from GitHub Actions and publishes it at
# https://cdn.mediarr.app/apps/mediarr.apk. Runs from cron. Does nothing when there is no new build.
# The signing key stays on this server: Android refuses an update signed with any other key.
set -euo pipefail

REPO=mmzlopasa/mediarr-dev
TOKEN_FILE=$HOME/.config/mediarr-gh-token
KEY_DIR=$HOME/.config/mediarr-android
TOOLS_DIR=$HOME/.local/share/mediarr-android
DEST_DIR=$HOME/mediarr-apps
DEST=$DEST_DIR/mediarr.apk
STATE=$DEST_DIR/.apk-run-id
JAVA_IMAGE=eclipse-temurin:21-jre
TOOLS_URL=https://dl.google.com/android/repository/build-tools_r34-linux.zip

exec 9>"$DEST_DIR/.pull-apk.lock"
flock -n 9 || exit 0

github() {
	printf 'header = "Authorization: Bearer %s"\n' "$(cat "$TOKEN_FILE")" |
		curl -K - -fsSL --max-time "${2:-30}" -H 'Accept: application/vnd.github+json' "$1"
}

json() { python3 -I -c "import json,sys;d=json.load(sys.stdin);$1"; }

runs=$(github "https://api.github.com/repos/$REPO/actions/workflows/android.yml/runs?branch=main&status=success&per_page=5")
run_id=$(json "
r=[x for x in d['workflow_runs'] if x['conclusion']=='success']
print(r[0]['id'] if r else '')" <<<"$runs")
[ -n "$run_id" ] || exit 0
[ "$(cat "$STATE" 2>/dev/null || true)" != "$run_id" ] || exit 0

artifacts=$(github "https://api.github.com/repos/$REPO/actions/runs/$run_id/artifacts")
url=$(json "a=[x for x in d['artifacts'] if x['name']=='Mediarr-apk' and not x['expired']];print(a[0]['archive_download_url'] if a else '')" <<<"$artifacts")
[ -n "$url" ] || exit 0

if [ ! -f "$TOOLS_DIR/apksigner.jar" ]; then
	mkdir -p "$TOOLS_DIR"
	curl -fsSL --max-time 300 -o "$TOOLS_DIR/tools.zip" "$TOOLS_URL"
	unzip -qoj "$TOOLS_DIR/tools.zip" '*/lib/apksigner.jar' -d "$TOOLS_DIR"
	rm "$TOOLS_DIR/tools.zip"
fi

java_run() {
	docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
		-v "$KEY_DIR:/key" -v "$TOOLS_DIR:/tools:ro" -v "$work:/work" "$JAVA_IMAGE" "$@"
}

work=$(mktemp -d "$DEST_DIR/.pull-apk-XXXXXX")
trap 'rm -rf "$work"' EXIT

if [ ! -f "$KEY_DIR/release.jks" ]; then
	mkdir -p "$KEY_DIR"
	chmod 700 "$KEY_DIR"
	(umask 077 && openssl rand -hex 24 >"$KEY_DIR/password")
	java_run keytool -genkeypair -keystore /key/release.jks -storepass:file /key/password \
		-alias mediarr -keyalg RSA -keysize 4096 -validity 36500 -dname "CN=Mediarr" >/dev/null 2>&1
	chmod 600 "$KEY_DIR/release.jks"
	echo "$(date -Is) created a new signing key in $KEY_DIR. Keep a copy of it safe."
fi

github "$url" 300 >"$work/artifact.zip"
unzip -qo "$work/artifact.zip" mediarr-unsigned.apk -d "$work"
java_run java -jar /tools/apksigner.jar sign --ks /key/release.jks --ks-pass file:/key/password \
	--ks-key-alias mediarr --out /work/mediarr.apk /work/mediarr-unsigned.apk
# Never replace a working download with something that does not verify.
java_run java -jar /tools/apksigner.jar verify /work/mediarr.apk

chmod 644 "$work/mediarr.apk"
mv "$work/mediarr.apk" "$DEST"
printf '%s\n' "$run_id" >"$STATE"
echo "$(date -Is) published the Android build from run $run_id"
