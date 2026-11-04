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
cp -r "$ROOT/public-repo/.github/." "$EXPORT/.github/"
cp "$ROOT/public-repo/README.md" "$EXPORT/README.md"
cp "$ROOT/public-repo/docker-README.md" "$EXPORT/docker/README.md"

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
[ -d "$PUBLIC_DIR/.git" ] || git clone -q "$PUBLIC_URL" "$PUBLIC_DIR"
git -C "$PUBLIC_DIR" fetch -q origin || true
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
git -C "$PUBLIC_DIR" push -q origin main
if [ -n "$TAG" ]; then
  git -C "$PUBLIC_DIR" -c user.name=SCYDE -c user.email=dev@scyde.dev tag -a "$TAG" -m "$TAG"
  git -C "$PUBLIC_DIR" push -q origin "$TAG"
fi
echo "Published $(git -C "$PUBLIC_DIR" rev-parse --short HEAD) ${TAG}"
