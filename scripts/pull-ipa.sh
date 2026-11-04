#!/bin/bash
# Copies the newest successful iOS build from GitHub Actions to the folder behind
# https://cdn.mediarr.app/apps/mediarr.ipa. Runs from cron. Does nothing when there is no new build.
set -euo pipefail

REPO=mediarr-app/mediarr-dev
TOKEN_FILE=$HOME/.config/mediarr-gh-token
DEST_DIR=$HOME/mediarr-apps
DEST=$DEST_DIR/mediarr.ipa
STATE=$DEST_DIR/.ipa-run-id
BUNDLE_ID=app.mediarr.mediarr

exec 9>"$DEST_DIR/.pull.lock"
flock -n 9 || exit 0

# The token goes through stdin, so it never appears in the process list.
github() {
	printf 'header = "Authorization: Bearer %s"\n' "$(cat "$TOKEN_FILE")" |
		curl -K - -fsSL --max-time "${2:-30}" -H 'Accept: application/vnd.github+json' "$1"
}

json() { python3 -I -c "import json,sys;d=json.load(sys.stdin);$1"; }

runs=$(github "https://api.github.com/repos/$REPO/actions/workflows/ios.yml/runs?branch=main&status=success&per_page=1")
run_id=$(json "r=d['workflow_runs'];print(r[0]['id'] if r else '')" <<<"$runs")
[ -n "$run_id" ] || exit 0
[ "$(cat "$STATE" 2>/dev/null || true)" != "$run_id" ] || exit 0

artifacts=$(github "https://api.github.com/repos/$REPO/actions/runs/$run_id/artifacts")
url=$(json "a=[x for x in d['artifacts'] if x['name']=='Mediarr-ipa' and not x['expired']];print(a[0]['archive_download_url'] if a else '')" <<<"$artifacts")
if [ -z "$url" ]; then
	echo "$(date -Is) run $run_id has no build to download"
	exit 1
fi

work=$(mktemp -d "$DEST_DIR/.pull-XXXXXX")
trap 'rm -rf "$work"' EXIT
github "$url" 300 >"$work/artifact.zip"
unzip -qo "$work/artifact.zip" Mediarr.ipa -d "$work"

# Never replace a working download with something that is not this app.
unzip -tq "$work/Mediarr.ipa" >/dev/null
unzip -qo "$work/Mediarr.ipa" Payload/Runner.app/Info.plist -d "$work/check"
build=$(python3 -I - "$work/check/Payload/Runner.app/Info.plist" "$BUNDLE_ID" <<'PY'
import plistlib, sys
info = plistlib.load(open(sys.argv[1], 'rb'))
if info.get('CFBundleIdentifier') != sys.argv[2]:
    sys.exit('unexpected bundle id: %s' % info.get('CFBundleIdentifier'))
print('%s (%s)' % (info.get('CFBundleShortVersionString'), info.get('CFBundleVersion')))
PY
)

chmod 644 "$work/Mediarr.ipa"
mv "$work/Mediarr.ipa" "$DEST"
printf '%s\n' "$run_id" >"$STATE"
echo "$(date -Is) published build $build from run $run_id"
