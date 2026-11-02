#!/bin/sh
# Fails if any page scores below 95 for accessibility in either theme.
set -e
CHROME_PATH=$(ls -d /ms-playwright/chromium-*/chrome-linux*/chrome | head -1)
export CHROME_PATH
out=$(mktemp -d)
for theme in dark light; do
	for path in / /admin /login /dev/components; do
		report="$out/report.json"
		node node_modules/lighthouse/cli/index.js "http://127.0.0.1:9852$path" \
			--only-categories=accessibility --output=json --output-path="$report" --quiet \
			--chrome-flags="--headless=new --no-sandbox --disable-gpu --force-prefers-color-scheme=$theme" >/dev/null 2>&1
		node -e "
			const score = Math.round(require('$report').categories.accessibility.score * 100);
			console.log('$theme $path', score);
			if (score < 95) process.exit(1);
		"
	done
done
