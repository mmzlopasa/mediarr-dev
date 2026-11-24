#!/bin/bash
# Copies the newest iOS builds from GitHub Actions to the folder behind cdn.mediarr.app/apps/.
# Runs from cron. Does nothing when there is no new build. Without an argument, both channels.
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
DEST_DIR=$HOME/mediarr-apps
DEST=$DEST_DIR/mediarr$SUFFIX.ipa
STATE=$DEST_DIR/.ipa$SUFFIX-run-id
ARTIFACT=Mediarr-ipa$SUFFIX
BUNDLE_ID=app.mediarr.mediarr
[ "$CHANNEL" = stable ] || BUNDLE_ID=app.mediarr.mediarr.dev
# Far above any real build: the .ipa is about 15 MB.
MAX_BYTES=$((1024 * 1024 * 1024))

mkdir -p "$DEST_DIR"
exec 9>"$DEST_DIR/.pull$SUFFIX.lock"
flock -n 9 || exit 0

# The token goes through stdin, so it never appears in the process list. curl does not send it on
# to the storage host a download is redirected to.
github() {
	printf 'header = "Authorization: Bearer %s"\n' "$(cat "$TOKEN_FILE")" |
		curl -K - -fsSL --proto '=https' --max-time "${2:-30}" --max-filesize "$MAX_BYTES" \
			-H 'Accept: application/vnd.github+json' "$1"
}

check() { python3 -I "$CHECK" "$@"; }

runs=$(github "https://api.github.com/repos/$REPO/actions/workflows/ios.yml/runs?status=completed&per_page=30")
run_id=$(check run "$CHANNEL" ios.yml <<<"$runs")
[ -n "$run_id" ] || exit 0
[ "$(cat "$STATE" 2>/dev/null || true)" != "$run_id" ] || exit 0

artifacts=$(github "https://api.github.com/repos/$REPO/actions/runs/$run_id/artifacts")
url=$(check artifact "$ARTIFACT" <<<"$artifacts")
# A cancelled or failed run has none, and the build already published stays.
[ -n "$url" ] || exit 0

work=$(mktemp -d "$DEST_DIR/.pull-XXXXXX")
trap 'rm -rf "$work"' EXIT
github "$url" 300 >"$work/artifact.zip"
check extract "$work/artifact.zip" Mediarr.ipa "$work/Mediarr.ipa" "$MAX_BYTES"
# Never replace a working download with something that is not this app.
build=$(check ipa "$work/Mediarr.ipa" "$BUNDLE_ID")

chmod 644 "$work/Mediarr.ipa"
# Same folder, so the switch is a rename: a download never gets half a file.
mv -f "$work/Mediarr.ipa" "$DEST"
printf '%s\n' "$run_id" >"$work/run-id"
mv -f "$work/run-id" "$STATE"
echo "$(date -Is) published $CHANNEL build $build from run $run_id"
