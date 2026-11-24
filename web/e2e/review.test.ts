import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test.use({ reducedMotion: 'reduce' });

test('a session that ends while the app is open goes to sign-in', async ({ page, context }) => {
	await signIn(page, 'user');
	await page.goto('/');
	await expect(page.locator('main#main')).toBeVisible();
	// Signed out elsewhere: the next answer of the API is 401.
	await context.clearCookies();
	await page.evaluate(() =>
		document.querySelector<HTMLAnchorElement>('a[href="/albums"]')?.click()
	);
	await expect(page).toHaveURL(/\/login\?next=/);
});

test('an upload on its way can be stopped', async ({ page }) => {
	await signIn(page, 'uploader');
	// The server never answers, so the file stays on its way until it is stopped.
	await page.route('**/api/uploads', () => undefined);
	await page.goto('/');
	await page.locator('input[type=file]').last().setInputFiles(photo('stopped.jpg'));
	const stop = page.getByRole('button', { name: /stopped\.jpg/ });
	await expect(stop).toBeVisible();
	await stop.click();
	await expect(page.getByText('stopped.jpg')).toHaveCount(0);
});

test('devices that did not load are not shown with a made-up setting', async ({ page }) => {
	await signIn(page, 'user');
	await page.route('**/api/me/backup-devices', (route) =>
		route.fulfill({ status: 500, json: { message: 'down' } })
	);
	await page.goto('/account/devices');
	await expect(page.getByRole('alert').first()).toBeVisible();
	await expect(page.locator('select')).toHaveCount(0);
});

test('the language menu on sign-in has a name in the chosen language', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'hr'));
	await page.goto('/login');
	await expect(page.locator('summary[aria-label="Jezik: HR"]').first()).toBeAttached();
});
