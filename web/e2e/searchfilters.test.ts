import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('filters narrow a search, show as chips, and are taken away again', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const names = [`filter-a-${Date.now()}.jpg`, `filter-b-${Date.now()}.jpg`];
	await page.goto('/');
	await page.locator('main').waitFor();
	await page
		.locator('input[type=file]')
		.last()
		.setInputFiles(names.map((name) => photo(name)));
	const ids: string[] = [];
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=200')).json();
				ids.length = 0;
				for (const name of names) {
					const found = list.items.find(
						(asset: { originalName: string; status: string }) =>
							asset.originalName === name && asset.status === 'ready'
					);
					if (found) ids.push(found.id);
				}
				return ids.length;
			},
			{ timeout: 60_000 }
		)
		.toBe(2);
	const bulk = await page.request.post('/api/assets/bulk', {
		data: { ids: [ids[0]], action: 'favorite' }
	});
	expect(bulk.ok()).toBe(true);
	const album = await (
		await page.request.post('/api/albums', { data: { title: `Filter album ${Date.now()}` } })
	).json();
	await page.request.post(`/api/albums/${album.id}/assets`, { data: { ids } });

	await page.goto('/search');
	await page.getByRole('button', { name: 'Filters' }).click();
	const panel = page.getByRole('form', { name: 'Filters' });
	await panel.getByLabel('Favourites only').check();
	await panel.getByRole('button', { name: 'Apply' }).click();
	const chips = page.getByRole('list', { name: 'Filters in this search' });
	await expect(chips).toContainText('Favourites');
	await expect(page.locator('.search-grid button')).toHaveCount(1);
	await expect(page.getByRole('button', { name: 'Filters · 1' })).toBeVisible();

	await chips.getByRole('button', { name: 'Remove Favourites' }).click();
	await expect(page.getByText('or choose filters')).toBeVisible();

	// From an album, its search is narrowed to it.
	await page.goto(`/albums/${album.id}`);
	await page.getByRole('link', { name: 'Search in album' }).click();
	await expect(chips).toContainText(`In album: ${album.title}`);
	await expect(page.locator('.search-grid button')).toHaveCount(2);
});
