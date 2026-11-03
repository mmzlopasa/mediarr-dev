// Writes the map's default style files and fetches its fonts and icons. Run with:
//   cd web && node ../scripts/map-style.mjs <folder served as https://cdn.mediarr.app/maps/>
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(join(process.cwd(), 'package.json'));
const { layers, namedFlavor } = await import(require.resolve('@protomaps/basemaps'));

const folder = process.argv[2];
if (!folder) throw new Error('name the folder to write to');
const base = process.argv[3] ?? 'https://cdn.mediarr.app/maps';

for (const flavor of ['light', 'dark']) {
	const style = {
		version: 8,
		glyphs: `${base}/fonts/{fontstack}/{range}.pbf`,
		sprite: `${base}/sprites/v4/${flavor}`,
		sources: {
			protomaps: {
				type: 'vector',
				url: `pmtiles://${base}/planet.pmtiles`,
				attribution: '© OpenStreetMap, Protomaps'
			}
		},
		layers: layers('protomaps', namedFlavor(flavor), { lang: 'en' })
	};
	writeFileSync(join(folder, `style-${flavor}.json`), JSON.stringify(style));
}

if (!existsSync(join(folder, 'fonts'))) {
	mkdirSync(folder, { recursive: true });
	execFileSync(
		'sh',
		[
			'-c',
			`curl -sL https://github.com/protomaps/basemaps-assets/archive/refs/heads/main.tar.gz | tar xz --strip-components=1 -C "${folder}" basemaps-assets-main/fonts basemaps-assets-main/sprites`
		],
		{ stdio: 'inherit' }
	);
}
