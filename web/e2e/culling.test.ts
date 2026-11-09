import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('a shoot is gone through, compared, and its picks and rejects dealt with', async ({
	page
}) => {
	test.setTimeout(120_000);
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const stamp = Date.now();
	const names = [1, 2, 3].map((n) => `cull-${stamp}-${n}.jpg`);
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
	const marks = async () => {
		const answer = await page.request.post('/api/assets/pick/read', { data: { ids } });
		const { items } = (await answer.json()) as {
			items: { id: string; pick: number; rating: number }[];
		};
		return ids.map((id) => items.find((item) => item.id === id)?.pick);
	};

	await page.goto('/');
	const tiles = ids.map((id) =>
		page.locator('.tl-tile', { has: page.locator(`img[src*="${id}"]`) })
	);
	await expect(tiles[2]).toBeAttached({ timeout: 20_000 });
	for (const tile of tiles) await tile.locator('.tl-check').click();
	await page
		.getByRole('toolbar', { name: 'Selected photos' })
		.getByRole('button', { name: 'Cull' })
		.click();

	const cull = page.getByRole('dialog', { name: 'Cull' });
	await expect(cull.getByTestId('cull-tally')).toHaveText('0 picked · 0 rejected');
	await expect(cull.getByTestId('cull-position')).toHaveText('1 / 3');

	// The newest first: the order of the timeline. Each verdict moves on to the next photo.
	const order = await cull
		.locator('.cull-thumb img')
		.evaluateAll((images) =>
			images.map((image) => (image as HTMLImageElement).src.match(/assets\/([^/]+)\//)?.[1] ?? '')
		);
	await page.keyboard.press('p');
	await expect(cull.getByTestId('cull-position')).toHaveText('2 / 3');
	await page.keyboard.press('x');
	await expect(cull.getByTestId('cull-position')).toHaveText('3 / 3');
	await expect(cull.getByTestId('cull-tally')).toHaveText('1 picked · 1 rejected');
	await expect
		.poll(marks)
		.toEqual(ids.map((id) => (id === order[0] ? 1 : id === order[1] ? -1 : 0)));

	// Stars with a number.
	await page.keyboard.press('4');
	await expect(cull.getByRole('button', { name: '4 of 5 stars' })).toHaveAttribute(
		'aria-pressed',
		'true'
	);

	// Two side by side, zoomed together.
	await page.keyboard.press('c');
	await page.keyboard.press('ArrowLeft');
	await page.keyboard.press('c');
	await expect(cull.locator('.cull-pane')).toHaveCount(2);
	await page.keyboard.press('z');
	const scales = await cull
		.locator('.cull-pane img.viewer-media:first-child')
		.evaluateAll((images) => images.map((image) => (image as HTMLElement).style.transform));
	expect(scales[0]).toBe(scales[1]);
	await page.keyboard.press('z');
	await page.keyboard.press('Escape');
	await expect(cull.locator('.cull-pane')).toHaveCount(1);

	// The picks become an album.
	await cull.getByRole('button', { name: 'Picks to new album' }).click();
	const title = `Cull ${stamp}`;
	await page.getByRole('dialog', { name: 'Picks to new album' }).getByLabel('Name').fill(title);
	await page.getByRole('button', { name: 'Create' }).click();
	await expect(page.getByText(`1 photo is in the album ${title}`)).toBeVisible();

	// The rejects go to the trash, after asking.
	await cull.getByRole('button', { name: 'Rejects to trash' }).click();
	await expect(page.getByText('1 rejected photo moves to the trash')).toBeVisible();
	await page.getByRole('button', { name: 'Delete' }).click();
	await expect(cull.getByTestId('cull-position')).toHaveText(/\/ 2$/);
	await expect
		.poll(async () => (await marks()).filter((pick) => pick === undefined).length)
		.toBe(1);

	await cull.getByRole('button', { name: 'Close' }).click();
	await expect(cull).toBeHidden();

	// The album narrows to a mark, and so does a search.
	const albums = await (await page.request.get('/api/albums?sort=updated')).json();
	const album = albums.find((entry: { title: string }) => entry.title === title);
	await page.goto(`/albums/${album.id}`);
	await expect(page.locator('.tl-tile')).toHaveCount(1, { timeout: 20_000 });
	await page.locator('.alb-filter select').selectOption({ label: 'Rejects' });
	await expect(page.getByText('No photos have this mark.')).toBeVisible();
	await page.locator('.alb-filter select').selectOption({ label: 'Picks' });
	await expect(page.locator('.tl-tile')).toHaveCount(1);

	await page.goto('/search?pick=1');
	await expect(page.locator(`img[src*="${order[0]}"]`).first()).toBeVisible({ timeout: 20_000 });
	await expect(page.locator(`img[src*="${order[1]}"]`)).toHaveCount(0);

	await page.request.delete(`/api/albums/${album.id}`);
	await page.request.post('/api/assets/bulk', { data: { ids, action: 'delete' } });
});
