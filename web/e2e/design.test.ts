import { expect, test, type Page } from '@playwright/test';
import { signIn } from './helpers';

// The approved Lightbox design, kept as screenshots. A change to the look must be intended: run
// `make e2e-design-update`, look at the new screenshots, and commit them with the change.
// Pages whose content comes from the database are shown with fixed answers, so that only the
// design is compared; the app itself always reads the real ones.

const widths = [1440, 1024, 390];
const themes = ['dark', 'light'] as const;

const overview = {
	users: 0,
	photos: 0,
	videos: 0,
	processing: 0,
	failed: 0,
	libraryBytes: 0,
	diskTotalBytes: 0,
	diskFreeBytes: 0,
	jobs: { queued: 0, running: 0, completed: 0, failed: 0 },
	version: 'test',
	databaseVersion: '17.0'
};

async function open(page: Page, path: string, theme: string) {
	await page.addInitScript((t) => {
		localStorage.setItem('mediarr_theme', t);
		localStorage.setItem('mediarr_lang', 'en');
	}, theme);
	if (path !== '/login' && !path.startsWith('/dev/')) await signIn(page, 'admin');
	await page.route('**/api/admin/overview', (route) => route.fulfill({ json: overview }));
	await page.goto(path);
	await page.locator('main').first().waitFor();
	await page.waitForLoadState('networkidle');
	await page.evaluate(() => document.fonts.ready);
	await page.mouse.move(0, 0);
}

test.use({ reducedMotion: 'reduce' });

for (const width of widths) {
	for (const theme of themes) {
		test.describe(`${width}px ${theme}`, () => {
			test.use({ viewport: { width, height: 900 }, colorScheme: theme });

			test('sign-in matches the approved design', async ({ page }) => {
				await open(page, '/login', theme);
				await expect(page).toHaveScreenshot(`login-${width}-${theme}.png`, {
					fullPage: true,
					animations: 'disabled',
					caret: 'hide',
					maxDiffPixelRatio: 0.001
				});
			});

			test('components match the approved design', async ({ page }) => {
				await open(page, '/dev/components', theme);
				await expect(page.locator('#zip-components')).toHaveScreenshot(
					`components-${width}-${theme}.png`,
					{ animations: 'disabled', caret: 'hide', maxDiffPixelRatio: 0.001 }
				);
			});
		});
	}
}
