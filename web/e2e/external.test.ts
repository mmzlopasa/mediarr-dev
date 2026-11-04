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
	await page.getByLabel(/Čije su ovo fotke|Whose photos these are/).selectOption(librarian.id);
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

test('an import can be started from the settings, and reports what it did', async ({ page }) => {
	await signIn(page, 'admin');
	const users = await (await page.request.get('/api/admin/users')).json();
	const owner = users.find((user: { email: string }) => user.email === 'e2e-librarian@example.com');
	await page.goto('/admin/settings');
	await page.getByTestId('import-source').selectOption('icloud');
	await page.getByTestId('import-owner').selectOption(owner.id);
	await page
		.getByLabel(/Mapa unutar vanjske biblioteke|Folder inside the external library/)
		.fill('e2e-no-such-folder');
	await page.getByRole('button', { name: /Pokreni uvoz|Start the import/ }).click();
	const entry = page.locator('[data-import="icloud"]').first();
	await expect(entry).toContainText('failed', { timeout: 30000 });
	await expect(entry).toContainText(/not found/);
});
