#!/bin/bash
# Publishes the production part of this repository to the public one.
#   scripts/publish-public.sh --check            shows what would be published
#   scripts/publish-public.sh "message" [v1.2.3] publishes it, and a tag starts the image build
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PUBLIC_URL=git@github.com:mediarr-app/mediarr.git
PUBLIC_DIR=$HOME/mediarr-public
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/mediarr_public_deploy -o IdentitiesOnly=yes"
INCLUDE=(server web machine-learning open-api LICENSE SECURITY.md .editorconfig .gitignore .dockerignore
  .github/ISSUE_TEMPLATE .github/pull_request_template.md
  docker/docker-compose.yml docker/docker-compose.prod.yml docker/example.env)
EXCLUDE=(server/.air.toml server/cmd/uploadtest web/e2e web/bench web/playwright.config.ts
  web/playwright.bench.config.ts web/.vscode)

[ -z "$(git -C "$ROOT" status --porcelain)" ] || { echo "Commit your changes first."; exit 1; }
EXPORT=$(mktemp -d /tmp/mediarr-export-XXXX)
trap 'rm -rf "$EXPORT"' EXIT
git -C "$ROOT" archive HEAD "${INCLUDE[@]}" | tar -x -C "$EXPORT"
for path in "${EXCLUDE[@]}"; do rm -rf "${EXPORT:?}/$path"; done
# The public repository's own files come from git too: anything ignored or left lying around in
# public-repo/ stays here.
PUBLIC_FILES=$EXPORT/.public-repo
mkdir "$PUBLIC_FILES"
git -C "$ROOT" archive HEAD public-repo | tar -x -C "$PUBLIC_FILES"
cp -r "$PUBLIC_FILES/public-repo/.github/." "$EXPORT/.github/"
cp "$PUBLIC_FILES/public-repo/README.md" "$EXPORT/README.md"
cp -r "$PUBLIC_FILES/public-repo/design" "$EXPORT/design"
cp "$PUBLIC_FILES/public-repo/docker-README.md" "$EXPORT/docker/README.md"
rm -rf "$PUBLIC_FILES"

FORBID=$HOME/.config/mediarr-publish-forbid
[ -f "$FORBID" ] || { echo "Missing $FORBID."; exit 1; }
# Binary files too (an image's metadata, a font's names), and the names of files.
if grep -rail -f "$FORBID" "$EXPORT"; then
  echo "The export holds words that must not be published."; exit 1
fi
if (cd "$EXPORT" && find . | grep -i -f "$FORBID"); then
  echo "The export holds file names that must not be published."; exit 1
fi
# Keys, certificates, local settings and links that could point anywhere on this server.
SECRETS=$(cd "$EXPORT" && find . \( -type l -o -type f \( -name '.env' -o -name '.env.*' ! -name '.env.example' \
  -o -name '*.jks' -o -name '*.keystore' -o -name '*.p12' -o -name '*.pem' -o -name '*.key' \
  -o -name 'id_rsa*' -o -name 'id_ed25519*' -o -name '*.mobileprovision' -o -name 'local.properties' \
  -o -name 'CLAUDE.md' -o -name 'PLAN.md' \) \) -print)
if [ -n "$SECRETS" ]; then
  echo "$SECRETS"
  echo "The export holds files that must not be published."; exit 1
fi

if [ "${1:-}" = "--check" ]; then
  (cd "$EXPORT" && find . -maxdepth 2 -not -path './server/*' -not -path './web/*' -not -path './machine-learning/*' | sort)
  du -sh "$EXPORT"
  [ -z "${EXPORT_TO:-}" ] || cp -r "$EXPORT/." "$EXPORT_TO/"
  echo "Check passed, nothing was published."
  exit 0
fi

MESSAGE=${1:?give a commit message}
TAG=${2:-}
if printf '%s\n' "$MESSAGE" | grep -qi -f "$FORBID"; then
  echo "The message holds words that must not be published."; exit 1
fi
# Only a version starts the image build; anything else would build images without a tag.
if [ -n "$TAG" ] && ! [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "A tag looks like v1.2.3 or v1.2.3-rc1."; exit 1
fi
[ -d "$PUBLIC_DIR/.git" ] || git clone -q "$PUBLIC_URL" "$PUBLIC_DIR"
# Without the newest state the export would be compared with an old one.
git -C "$PUBLIC_DIR" fetch -q --tags origin
if [ -n "$TAG" ] && git -C "$PUBLIC_DIR" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "$TAG is already published."; exit 1
fi
git -C "$PUBLIC_DIR" checkout -q -B main
git -C "$PUBLIC_DIR" rev-parse -q --verify origin/main >/dev/null && git -C "$PUBLIC_DIR" reset -q --hard origin/main
find "$PUBLIC_DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -r "$EXPORT/." "$PUBLIC_DIR/"
git -C "$PUBLIC_DIR" add -A
if git -C "$PUBLIC_DIR" diff --cached --quiet; then
  echo "Nothing changed in the production part."
else
  git -C "$PUBLIC_DIR" -c user.name=SCYDE -c user.email=dev@scyde.dev commit -q -m "$MESSAGE"
fi
# GitHub sometimes refuses a push for a moment, and the same push then goes through.
push() {
  local wait=2
  until git -C "$PUBLIC_DIR" push -q origin "$1"; do
    [ "$wait" -le 16 ] || return 1
    sleep "$wait"
    wait=$((wait * 2))
  done
}
push main
if [ -n "$TAG" ]; then
  git -C "$PUBLIC_DIR" -c user.name=SCYDE -c user.email=dev@scyde.dev tag -a "$TAG" -m "$TAG"
  push "$TAG"
fi
echo "Published $(git -C "$PUBLIC_DIR" rev-parse --short HEAD) ${TAG}"
