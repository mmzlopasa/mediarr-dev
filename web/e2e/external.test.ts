import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test.setTimeout(180000);

test('an external folder is read and browsed, without copying', async ({ page }) => {
	await signIn(page, 'admin');
	const users = await (await page.request.get('/api/admin/users')).json();
	const librarian = users.find(
		(user: { email: string }) => user.email === 'e2e-librarian@example.com'
	);

	await page.goto('/admin/settings');
	await expect(
		page.getByRole('heading', { name: /Vanjska biblioteka|External library/ })
	).toBeVisible();
	await page.locator('select').selectOption(librarian.id);
	await page.getByRole('button', { name: /Spremi i pregledaj|Save and scan/ }).click();
	await expect(page.getByRole('button', { name: /Pregledaj sada|Scan now/ })).toBeVisible();

	await page.context().clearCookies();
	await signIn(page, 'librarian');
	await expect(async () => {
		await page.goto('/folders');
		await expect(page.locator('.folder-tile', { hasText: 'e2e-folder' })).toBeVisible({
			timeout: 2000
		});
	}).toPass({ timeout: 120000, intervals: [3000] });
	await page.locator('.folder-tile', { hasText: 'e2e-folder' }).click();
	await page.locator('.folder-tile', { hasText: 'inner' }).click();
	await expect(page).toHaveURL(/path=e2e-folder%2Finner/);
	await page.locator('.folder-photo').click();
	await expect(page.locator('.viewer-media').first()).toBeVisible();
	await page.goBack();
	await page.getByRole('button', { name: /Vrh|Top/ }).click();
	await expect(page.locator('.folder-tile', { hasText: 'e2e-folder' })).toBeVisible();

	// It is on the timeline like any other photo.
	await page.goto('/');
	await expect(page.locator('.tl-tile')).toHaveCount(1);
});
