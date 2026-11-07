import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('Recently added shows a photo by when it came in, and the upload list clears itself', async ({
	page
}) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const name = `recent-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	await expect(page.getByText('Uploaded: 1')).toBeVisible({ timeout: 30_000 });
	await expect(page.locator('.kv', { hasText: name })).toHaveCount(0, { timeout: 10_000 });

	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=200')).json();
				const found = list.items.find(
					(asset: { originalName: string; status: string }) =>
						asset.originalName === name && asset.status === 'ready'
				);
				id = found?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');

	await page.goto('/recent');
	await expect(page.getByRole('heading', { name: 'Recently added' })).toBeVisible();
	// The days in the grid are the days things came in: this one today.
	await expect(page.locator(`.tl-tile img[src*="${id}"]`)).toBeAttached({ timeout: 20_000 });
	await page.getByRole('navigation').getByRole('button', { name: 'More' }).click();
	await expect(page.getByRole('link', { name: 'Recently added' }).first()).toBeVisible();
});
