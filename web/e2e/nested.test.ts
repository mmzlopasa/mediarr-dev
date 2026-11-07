import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test('an album goes inside another, shows there, and moves back to the top', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const stamp = Date.now();
	const outer = await (
		await page.request.post('/api/albums', { data: { title: `Travels ${stamp}` } })
	).json();
	const loose = await (
		await page.request.post('/api/albums', { data: { title: `Japan ${stamp}` } })
	).json();

	await page.goto(`/albums/${outer.id}`);
	await page.getByRole('button', { name: 'Album inside' }).click();
	const make = page.getByRole('dialog', { name: 'New album inside' });
	await make.getByLabel('Name').fill(`2024 ${stamp}`);
	await make.getByRole('button', { name: 'Create' }).click();
	const inside = page.getByRole('region', { name: 'Albums inside' });
	await expect(inside.locator(`[data-album="2024 ${stamp}"]`)).toBeVisible();

	await page.goto(`/albums/${loose.id}`);
	await page.getByRole('button', { name: 'Move to…' }).click();
	const moveDialog = page.getByRole('dialog', { name: 'Move the album' });
	await moveDialog.getByLabel('Into').selectOption({ label: `Travels ${stamp}` });
	await moveDialog.getByRole('button', { name: 'Move', exact: true }).click();
	await expect(page.getByText('The album was moved.')).toBeVisible();
	await expect(page.getByRole('link', { name: `Travels ${stamp}` })).toBeVisible();

	// The list shows only what is at the top, with how many albums are inside.
	await page.goto('/albums');
	await expect(page.locator(`[data-album="Travels ${stamp}"]`)).toContainText('2 albums');
	await expect(page.locator(`[data-album="Japan ${stamp}"]`)).toHaveCount(0);

	// Not into itself, nor into an album inside it.
	await page.goto(`/albums/${outer.id}`);
	await page.getByRole('button', { name: 'Move to…' }).click();
	const moveAgain = page.getByRole('dialog', { name: 'Move the album' });
	const options = await moveAgain.getByLabel('Into').locator('option').allTextContents();
	expect(options.some((label) => label.includes(`2024 ${stamp}`))).toBe(false);
	expect(options.some((label) => label.includes(`Travels ${stamp}`))).toBe(false);
	await moveAgain.getByRole('button', { name: 'Cancel' }).click();

	// Deleting the one around keeps the albums that were in it.
	await page.locator('.ph-a').getByRole('button', { name: 'Delete' }).click();
	await page
		.getByRole('dialog', { name: 'Delete this album?' })
		.getByRole('button', { name: 'Delete' })
		.click();
	await expect(page).toHaveURL(/\/albums$/);
	await expect(page.locator(`[data-album="Japan ${stamp}"]`)).toBeVisible();
	await expect(page.locator(`[data-album="2024 ${stamp}"]`)).toBeVisible();

	const all = await (await page.request.get('/api/albums')).json();
	for (const album of all.filter((a: { title: string }) => a.title.endsWith(String(stamp)))) {
		await page.request.delete(`/api/albums/${album.id}`);
	}
});
