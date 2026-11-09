import { expect, test } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { signIn } from './helpers';

test.setTimeout(150000);

const day = (date: Date) => date.toISOString().slice(0, 10);

// The same day a month earlier, the last of that month when it is shorter, as the server counts it.
function monthBefore(date: Date) {
	const first = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() - 1, 1));
	const last = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 0)).getUTCDate();
	first.setUTCDate(Math.min(date.getUTCDate(), last));
	return first;
}

test('a month ago is worked out in the background, hidden, and brought back', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');

	// Tomorrow: a day not worked out yet for this account, so opening it starts the job.
	const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
	const target = day(monthBefore(tomorrow));
	// Three different pictures: copies of one would be taken for duplicates, which memories leave out.
	const fixtures = ['gps.jpg', 'pano.jpg', 'similar-a.jpg'];
	const names = fixtures.map((_, n) => `month-ago-${n}-${Date.now()}.jpg`);
	const files = fixtures.map((fixture, n) => ({
		name: names[n],
		mimeType: 'image/jpeg',
		buffer: Buffer.concat([
			readFileSync(join(import.meta.dirname, 'fixtures', fixture)),
			Buffer.from(`${names[n]}${Math.random()}`)
		])
	}));
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(files);

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
	const dated = await page.request.post('/api/assets/dates', {
		data: { ids, action: 'set', takenAt: `${target}T12:00:00+00:00` }
	});
	expect(dated.ok()).toBe(true);

	// Only now: the home page asks for memories too, and that would work them out before the dates.
	await page.route('**/api/memories?*', (route) => {
		const url = new URL(route.request().url());
		url.searchParams.set('date', day(tomorrow));
		return route.continue({ url: url.href });
	});

	await page.goto('/memories');
	await expect(page.getByRole('heading', { name: 'Memories' })).toBeVisible();
	const tile = page.getByRole('button', { name: /A month ago/ });
	await expect
		.poll(
			async () => {
				await page.reload();
				await page.getByRole('heading', { name: 'Memories' }).waitFor();
				return tile.count();
			},
			{ timeout: 60_000, intervals: [3000] }
		)
		.toBeGreaterThan(0);

	await tile.click();
	const story = page.getByRole('dialog');
	await story.getByRole('button', { name: 'Hide this memory' }).click();
	await expect(tile).toHaveCount(0);
	await page.reload();
	await page.getByRole('heading', { name: 'Memories' }).waitFor();
	await expect(tile).toHaveCount(0);

	// Remembered in the settings, and it can come back.
	await page.goto('/account');
	await expect(page.getByText('1 memory is hidden')).toBeVisible();
	await page.getByRole('button', { name: 'Show all again' }).click();
	await expect(page.getByText('Nothing is hidden.')).toBeVisible();
	await page.goto('/memories');
	await expect(tile.first()).toBeVisible();

	// A kind can be turned off.
	await page.goto('/account');
	await page.getByRole('checkbox', { name: 'A month ago' }).uncheck();
	await page.goto('/memories');
	await page.getByRole('heading', { name: 'Memories' }).waitFor();
	await expect(tile).toHaveCount(0);
	await page.goto('/account');
	await page.getByRole('checkbox', { name: 'A month ago' }).check();
});
