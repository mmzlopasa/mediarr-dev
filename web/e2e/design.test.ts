import { expect, test, type Page } from '@playwright/test';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import pixelmatch from 'pixelmatch';
import { PNG } from 'pngjs';
import { signIn } from './helpers';
import { adminPage, appPage, componentsPage, loginPage } from './reference/pages';

const REF_ORIGIN = 'http://reference.test';
const REF_DIR = join(import.meta.dirname, 'reference');
const OUT_DIR = join(import.meta.dirname, '..', 'test-results', 'design');
const MAX_DIFF_RATIO = 0.001;

const widths = [1440, 1024, 390];
const themes = ['dark', 'light'];
const pages = [
	{ name: 'app', path: '/', reference: appPage },
	{ name: 'admin', path: '/admin', reference: adminPage },
	{ name: 'login', path: '/login', reference: loginPage }
];

async function shoot(page: Page, selector?: string) {
	await page.evaluate(() => document.fonts.ready);
	await page.mouse.move(0, 0);
	const options = { animations: 'disabled', caret: 'hide' } as const;
	return selector
		? page.locator(selector).screenshot(options)
		: page.screenshot({ ...options, fullPage: true });
}

async function shootReference(page: Page, html: string, selector?: string) {
	await page.route(`${REF_ORIGIN}/**`, (route) => {
		const { pathname } = new URL(route.request().url());
		if (pathname === '/') return route.fulfill({ contentType: 'text/html', body: html });
		const type = extname(pathname) === '.css' ? 'text/css' : 'font/woff2';
		return route.fulfill({ contentType: type, body: readFileSync(join(REF_DIR, pathname)) });
	});
	await page.goto(`${REF_ORIGIN}/`);
	return shoot(page, selector);
}

async function shootMediarr(page: Page, path: string, theme: string, selector?: string) {
	await page.addInitScript((t) => {
		localStorage.setItem('mediarr_theme', t);
		localStorage.setItem('mediarr_lang', 'hr');
	}, theme);
	if (path !== '/login' && !path.startsWith('/dev/')) await signIn(page, 'admin');
	await page.goto(path);
	await page.locator(selector ?? 'main').waitFor();
	return shoot(page, selector);
}

function compare(name: string, reference: Buffer, actual: Buffer) {
	const a = PNG.sync.read(reference);
	const b = PNG.sync.read(actual);
	mkdirSync(OUT_DIR, { recursive: true });
	writeFileSync(join(OUT_DIR, `${name}-reference.png`), reference);
	writeFileSync(join(OUT_DIR, `${name}-mediarr.png`), actual);
	expect(`${b.width}x${b.height}`, `${name} size`).toBe(`${a.width}x${a.height}`);

	const diff = new PNG({ width: a.width, height: a.height });
	const pixels = pixelmatch(a.data, b.data, diff.data, a.width, a.height, { threshold: 0.1 });
	writeFileSync(join(OUT_DIR, `${name}-diff.png`), PNG.sync.write(diff));
	const ratio = pixels / (a.width * a.height);
	console.log(`${name}: ${pixels} px (${(ratio * 100).toFixed(4)}%)`);
	expect(ratio, `${name} differs from the reference`).toBeLessThanOrEqual(MAX_DIFF_RATIO);
}

test.use({ reducedMotion: 'reduce' });

for (const width of widths) {
	for (const theme of themes) {
		test.describe(`${width}px ${theme}`, () => {
			test.use({ viewport: { width, height: 900 }, colorScheme: theme as 'dark' | 'light' });

			for (const { name, path, reference } of pages) {
				test(`${name} matches the reference design`, async ({ page, browser }) => {
					const refPage = await browser.newPage({
						viewport: { width, height: 900 },
						colorScheme: theme as 'dark' | 'light',
						reducedMotion: 'reduce'
					});
					const expected = await shootReference(refPage, reference(theme));
					await refPage.close();
					const actual = await shootMediarr(page, path, theme);
					compare(`${name}-${width}-${theme}`, expected, actual);
				});
			}

			test('components match the reference design', async ({ page, browser }) => {
				const refPage = await browser.newPage({
					viewport: { width, height: 900 },
					colorScheme: theme as 'dark' | 'light',
					reducedMotion: 'reduce'
				});
				const expected = await shootReference(refPage, componentsPage(theme), '#zip-components');
				await refPage.close();
				const actual = await shootMediarr(page, '/dev/components', theme, '#zip-components');
				compare(`components-${width}-${theme}`, expected, actual);
			});
		});
	}
}
