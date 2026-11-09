import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('screenshots are found and moved to the trash from Clean up', async ({ page }) => {
	test.setTimeout(90_000);
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const name = `Screenshot_${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page
		.locator('input[type=file]')
		.last()
		.setInputFiles([photo(name)]);
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

	await page.goto('/cleanup');
	await page.getByRole('tab', { name: /Screenshots/ }).click();
	const tile = page.getByRole('button', { name });
	await expect(tile).toHaveAttribute('aria-pressed', 'true');
	// Everything else ticked here is left alone: only this one goes.
	const others = page.locator('.cln-pick[aria-pressed="true"]');
	for (const other of await others.all()) {
		if ((await other.getAttribute('aria-label')) !== name) await other.click();
	}
	await page.getByRole('button', { name: /^Move to the trash \(1 ·/ }).click();
	await page.getByRole('dialog').getByRole('button', { name: 'Move' }).click();
	await expect(page.getByRole('button', { name })).toHaveCount(0);
	// It is in the trash, where it can be restored.
	expect((await page.request.get(`/api/collections/trash/assets/${id}`)).status()).toBe(200);
});
