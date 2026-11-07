import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('a tag is renamed, and joined with another only after asking', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'organizer');
	const stamp = Date.now();
	const name = `tagrename-${stamp}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=200')).json();
				id = list.items.find((a: { originalName: string }) => a.originalName === name)?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');
	const first = `first-${stamp}`;
	const second = `second-${stamp}`;
	for (const tag of [first, second]) {
		const tagged = await page.request.post('/api/assets/tags', { data: { ids: [id], name: tag } });
		expect(tagged.ok()).toBe(true);
	}
	const tags = await (await page.request.get('/api/tags')).json();
	const firstTag = tags.find((t: { name: string }) => t.name === first);

	await page.goto(`/tags/${firstTag.id}`);
	await page.getByRole('button', { name: 'Rename' }).click();
	const form = page.getByRole('form', { name: 'Rename the tag' });
	await form.getByLabel('New name').fill(`Renamed ${stamp}`);
	await form.getByRole('button', { name: 'Save' }).click();
	await expect(page.getByRole('heading', { name: `Renamed ${stamp}` })).toBeVisible();

	await page.getByRole('button', { name: 'Rename' }).click();
	await form.getByLabel('New name').fill(second);
	page.once('dialog', (dialog) => dialog.accept());
	await form.getByRole('button', { name: 'Save' }).click();
	await expect(page.getByRole('heading', { name: second })).toBeVisible();
	const left = await (await page.request.get('/api/tags')).json();
	expect(left.some((t: { name: string }) => t.name === `Renamed ${stamp}`)).toBe(false);
	const joined = left.find((t: { name: string }) => t.name === second);
	await expect(page).toHaveURL(new RegExp(`/tags/${joined.id}`));

	await page.request.delete(`/api/tags/${joined.id}`);
});
