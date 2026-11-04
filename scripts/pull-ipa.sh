#!/bin/bash
# Copies the newest iOS builds from GitHub Actions to the folder behind cdn.mediarr.app/apps/.
# Runs from cron. Does nothing when there is no new build. Without an argument, both channels.
set -euo pipefail

CHANNEL=${1:-}
if [ -z "$CHANNEL" ]; then
	status=0
	"$0" stable || status=$?
	"$0" dev || status=$?
	exit "$status"
fi
case "$CHANNEL" in
stable) SUFFIX= ; ;;
dev) SUFFIX=-dev ;;
*) echo "usage: $0 [stable|dev]" >&2; exit 2 ;;
esac

REPO=mmzlopasa/mediarr-dev
TOKEN_FILE=$HOME/.config/mediarr-gh-token
DEST_DIR=$HOME/mediarr-apps
DEST=$DEST_DIR/mediarr$SUFFIX.ipa
STATE=$DEST_DIR/.ipa$SUFFIX-run-id
ARTIFACT=Mediarr-ipa$SUFFIX
BUNDLE_ID=app.mediarr.mediarr
[ "$CHANNEL" = stable ] || BUNDLE_ID=app.mediarr.mediarr.dev

exec 9>"$DEST_DIR/.pull$SUFFIX.lock"
flock -n 9 || exit 0

# The token goes through stdin, so it never appears in the process list.
github() {
	printf 'header = "Authorization: Bearer %s"\n' "$(cat "$TOKEN_FILE")" |
		curl -K - -fsSL --max-time "${2:-30}" -H 'Accept: application/vnd.github+json' "$1"
}

json() { python3 -I -c "import json,sys;d=json.load(sys.stdin);$1"; }

runs=$(github "https://api.github.com/repos/$REPO/actions/workflows/ios.yml/runs?status=completed&per_page=30")
# Stable comes only from a tag that passed everything. Dev is the newest build, even if a test failed.
run_id=$(CHANNEL=$CHANNEL json "
import os
stable=os.environ['CHANNEL']=='stable'
def wanted(x):
    if stable:
        return x['head_branch'].startswith('app-v') and x['conclusion'] == 'success'
    return x['head_branch'] == 'main' and x['conclusion'] in ('success', 'failure')
r = [x for x in d['workflow_runs'] if wanted(x)]
print(r[0]['id'] if r else '')" <<<"$runs")
[ -n "$run_id" ] || exit 0
[ "$(cat "$STATE" 2>/dev/null || true)" != "$run_id" ] || exit 0

artifacts=$(github "https://api.github.com/repos/$REPO/actions/runs/$run_id/artifacts")
url=$(json "a=[x for x in d['artifacts'] if x['name']=='$ARTIFACT' and not x['expired']];print(a[0]['archive_download_url'] if a else '')" <<<"$artifacts")
if [ -z "$url" ]; then
	# A cancelled or failed run has none, and the build already published stays.
	exit 0
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
echo "$(date -Is) published $CHANNEL build $build from run $run_id"
