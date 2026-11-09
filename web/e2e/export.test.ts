import { expect, test } from '@playwright/test';
import { readFile } from 'node:fs/promises';
import { photo, signIn } from './helpers';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
});

// Anyone takes their whole library away: the export runs in the background, then each ZIP part
// downloads with the originals and the metadata in it.
test('a whole library is exported and its part downloads', async ({ page }) => {
	test.setTimeout(150_000);
	await signIn(page, 'importer');
	// Exports of earlier runs go first, so that the list shows only this one.
	for (const old of await (await page.request.get('/api/exports')).json()) {
		if (old.status === 'running') await page.request.post(`/api/exports/${old.id}/cancel`);
		await page.request.delete(`/api/exports/${old.id}`);
	}

	const name = `export-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=200')).json();
				return list.items.some(
					(asset: { originalName: string; status: string }) =>
						asset.originalName === name && asset.status === 'ready'
				);
			},
			{ timeout: 60_000 }
		)
		.toBe(true);

	await page.goto('/account/export');
	await expect(page.getByRole('heading', { name: 'Export', level: 1 })).toBeVisible();
	await expect(page.getByText('Nothing has been exported yet.')).toBeVisible();
	await page.getByRole('button', { name: 'Export my library' }).click();
	await expect(page.getByText('The export has started.')).toBeVisible();

	const mine = page.getByRole('list', { name: 'Your exports' }).getByRole('listitem').first();
	await expect(mine).toHaveAttribute('data-export', 'done', { timeout: 90_000 });
	await expect(mine).toContainText('Ready');
	await expect(mine).toContainText('Can be downloaded until');

	const downloading = page.waitForEvent('download');
	await mine.getByRole('link', { name: 'Part 1' }).click();
	const download = await downloading;
	expect(download.suggestedFilename()).toMatch(/^mediarr-export-\d{4}-\d{2}-\d{2}-part-001\.zip$/);
	expect((await readFile(await download.path())).subarray(0, 2).toString()).toBe('PK');

	// Together the parts hold the new photo, and the last one the metadata about the whole library.
	const [done] = await (await page.request.get('/api/exports')).json();
	const parts: Buffer[] = [];
	for (const part of done.parts) {
		const response = await page.request.get(`/api/exports/${done.id}/parts/${part.number}`);
		expect(response.status()).toBe(200);
		parts.push(Buffer.from(await response.body()));
	}
	expect(parts.some((data) => data.includes(name))).toBe(true);
	expect(parts.at(-1)!.includes('mediarr-export.json')).toBe(true);
	expect(parts.at(-1)!.includes('README.txt')).toBe(true);

	// Removing it takes its files with it.
	await mine.getByRole('button', { name: 'Remove' }).click();
	await expect(page.getByText('Nothing has been exported yet.')).toBeVisible();
});
