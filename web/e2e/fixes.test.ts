import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('dates and places of selected photos are fixed after a preview', async ({ page }) => {
	test.setTimeout(90_000);
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const stamp = Date.now();
	const names = [1, 2].map((n) => `fix-${stamp}-${n}.jpg`);
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
	const before = (await (await page.request.get(`/api/assets/${ids[0]}`)).json()).localAt;
	// These two among the rest of the library, by their pictures.
	const tiles = ids.map((id) =>
		page.locator('.tl-tile', { has: page.locator(`img[src*="${id}"]`) })
	);
	const select = async () => {
		for (const tile of tiles) await tile.locator('.tl-check').click();
	};

	await page.goto('/');
	await expect(tiles[1]).toBeAttached({ timeout: 20_000 });
	await select();
	const bar = page.getByRole('toolbar', { name: 'Selected photos' });
	await expect(bar.locator('.selbar-n')).toHaveText('2');

	// One hour earlier (these photos are from now, and none goes into the future).
	await bar.getByRole('button', { name: 'Date and time' }).click();
	const dates = page.getByRole('form', { name: 'Date and time' });
	await dates.getByLabel('Direction').selectOption({ label: 'Earlier' });
	await dates.locator('label', { hasText: 'hours' }).locator('input').fill('1');
	const preview = page.getByRole('region', { name: 'Preview' });
	await expect(preview).toContainText('Will change: 2');
	expect((await (await page.request.get(`/api/assets/${ids[0]}`)).json()).localAt).toBe(before);
	await page.getByRole('button', { name: 'Save' }).click();
	await expect(page.getByText('Changed: 2')).toBeVisible();
	const after = (await (await page.request.get(`/api/assets/${ids[0]}`)).json()).localAt;
	expect(Date.parse(`${before}Z`) - Date.parse(`${after}Z`)).toBe(3_600_000);

	// A place by hand, for both.
	await expect(tiles[1]).toBeAttached({ timeout: 20_000 });
	await select();
	await bar.getByRole('button', { name: 'Location' }).click();
	const places = page.getByRole('form', { name: 'Location' });
	await places.locator('label', { hasText: 'Set a place' }).click();
	await places.getByLabel('Latitude').fill('43.5081');
	await places.getByLabel('Longitude').fill('16.4402');
	await expect(preview).toContainText('Will change: 2');
	await page.getByRole('button', { name: 'Save' }).click();
	// The notice of the dates may still be up, so the place itself is waited for.
	await expect
		.poll(async () => (await (await page.request.get(`/api/assets/${ids[1]}`)).json()).latitude)
		.toBeCloseTo(43.5081, 3);
});
