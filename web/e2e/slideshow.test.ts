import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('a slideshow plays an album and the open photo, and keeps its settings', async ({ page }) => {
	// Uploading and processing the three photos takes a good part of the default 30 seconds.
	test.setTimeout(90_000);
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const stamp = Date.now();
	const names = [1, 2, 3].map((n) => `slide-${stamp}-${n}.jpg`);
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
		.toBe(3);
	const album = await (
		await page.request.post('/api/albums', { data: { title: `Slides ${stamp}` } })
	).json();
	await page.request.post(`/api/albums/${album.id}/assets`, { data: { ids } });

	await page.goto(`/albums/${album.id}`);
	await page.getByRole('button', { name: 'Slideshow' }).click();
	const show = page.getByRole('dialog', { name: 'Slideshow' });
	await expect(show).toBeVisible();
	await expect(show.getByText('1 / 3')).toBeVisible();
	await show.getByRole('button', { name: 'Next' }).click();
	await expect(show.getByText('2 / 3')).toBeVisible();
	await show.getByRole('button', { name: 'Previous' }).click();
	await expect(show.getByText('1 / 3')).toBeVisible();

	// It goes on by itself, at the chosen pace, and remembers it.
	await show.getByRole('button', { name: 'Slideshow settings' }).click();
	const settings = show.getByRole('form', { name: 'Slideshow settings' });
	await settings.getByLabel('Pace').selectOption('3');
	await settings.getByLabel('Transition').selectOption('none');
	await expect(show.getByText('2 / 3')).toBeVisible({ timeout: 6_000 });
	await show.press(' ');
	await expect(show.getByRole('button', { name: 'Play' })).toBeVisible();
	const kept = await page.evaluate(() =>
		JSON.parse(localStorage.getItem('mediarr_slideshow') ?? '{}')
	);
	expect(kept.seconds).toBe(3);
	expect(kept.transition).toBe('none');

	await show.press('Escape');
	await expect(show).toHaveCount(0);

	// From the viewer, it starts with the open photo.
	await page.goto(`/albums/${album.id}?photo=${ids[0]}`);
	// The album has a Slideshow button of its own, under the viewer: this is the viewer's.
	await page
		.getByRole('dialog', { name: names[0] })
		.getByRole('button', { name: 'Slideshow' })
		.click();
	await expect(
		page.getByRole('dialog', { name: 'Slideshow' }).getByText(/^1 \/ \d+$/)
	).toBeVisible();

	await page.request.delete(`/api/albums/${album.id}`);
});
