// Checks the texts: a key used in the code but missing from English fails (svelte-check does that
// too, by type); a key nobody uses is reported; and how much of each language is translated.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const dir = new URL('../src/lib/i18n/', import.meta.url).pathname;
const en = JSON.parse(readFileSync(join(dir, 'en.json'), 'utf8'));
const keys = Object.keys(en);

function files(path) {
	return readdirSync(path).flatMap((name) => {
		const full = join(path, name);
		if (statSync(full).isDirectory()) return files(full);
		return /\.(svelte|ts)$/.test(name) && !name.endsWith('.test.ts') ? [full] : [];
	});
}
const code = files(new URL('../src', import.meta.url).pathname)
	.map((file) => readFileSync(file, 'utf8'))
	.join('\n');

const used = new Set([...code.matchAll(/\b[tk]\(\s*'([\w.]+)'/g)].map((match) => match[1]));
const missing = [...used].filter((key) => !(key in en));
const unused = keys.filter((key) => !used.has(key));

for (const lang of ['hr', 'de', 'sl']) {
	const catalog = JSON.parse(readFileSync(join(dir, `${lang}.json`), 'utf8'));
	const done = keys.filter((key) => catalog[key]).length;
	console.log(`${lang}: ${((100 * done) / keys.length).toFixed(1)} % (${done} of ${keys.length})`);
}
if (unused.length) console.warn(`not used anywhere (${unused.length}): ${unused.join(', ')}`);
if (missing.length) {
	console.error(`used but not in en.json: ${missing.join(', ')}`);
	process.exit(1);
}
