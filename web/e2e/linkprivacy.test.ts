import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('a link that hides faces asks who is looking, and the owner sees who opened it', async ({
	page,
	browser,
	baseURL
}) => {
	test.setTimeout(120_000);
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const title = `E2E private ${Date.now()}`;
	const album = await (await page.request.post('/api/albums', { data: { title } })).json();

	await page.goto(`/albums/${album.id}`);
	await expect(page.getByRole('heading', { name: title })).toBeVisible();
	// A file chosen before the page is ready would be lost; a person cannot be that quick.
	await page.waitForLoadState('networkidle');
	await page.locator('input[type=file]').last().setInputFiles(photo('private.jpg'));
	await expect(page.locator('.tl-tile')).toHaveCount(1, { timeout: 40_000 });

	// The link: every face hidden, and a name asked for.
	await page.getByRole('button', { name: 'Links' }).click();
	const dialog = page.getByRole('dialog', { name: 'Public links' });
	await dialog.getByLabel('Hide faces').selectOption('all');
	// What blurring cannot cover is said next to the option, from the album itself.
	await expect(
		dialog.getByText('A face the recognition did not find stays visible.', { exact: false })
	).toBeVisible();
	await expect(dialog.getByLabel('Remove camera details')).toBeChecked();
	await dialog.getByLabel('Ask for a name').check();
	await dialog.getByRole('button', { name: 'Create link' }).click();
	const address = dialog.getByLabel('Link address');
	await expect(address).toBeVisible();
	const url = await address.inputValue();
	await expect(dialog.getByRole('link', { name: 'Preview as a visitor' })).toHaveAttribute(
		'href',
		url
	);
	await expect(dialog.getByText('faces hidden', { exact: false })).toBeVisible();

	// A visitor, with no account, says who they are before seeing anything.
	const context = await browser.newContext({ baseURL });
	try {
		await context.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
		const guest = await context.newPage();
		await guest.goto(url);
		await expect(guest.getByRole('heading', { name: 'Who is looking?' })).toBeVisible();
		await expect(guest.getByRole('heading', { name: title })).toHaveCount(0);
		const token = url.split('/').pop();
		expect((await guest.request.get(`/api/public/${token}/buckets`)).status()).toBe(403);
		await guest.getByLabel('Your name').fill('Ana');
		await guest.getByRole('button', { name: 'Open' }).click();
		await expect(guest.getByRole('heading', { name: title })).toBeVisible();
		await expect(guest.getByText('Videos are not available on this link')).toBeVisible();
		await expect(guest.locator('.tl-tile')).toHaveCount(1, { timeout: 20_000 });
	} finally {
		await context.close();
	}

	// The owner sees the visit, with the name.
	await dialog.getByRole('button', { name: 'Close' }).click();
	await page.getByRole('button', { name: 'Links' }).click();
	await expect(dialog.getByText('Opened 1 time', { exact: false })).toBeVisible();
	await dialog.getByRole('button', { name: 'Who opened it' }).click();
	const visits = dialog.getByRole('region', { name: 'Who opened it' });
	await expect(visits.getByRole('cell', { name: 'Ana', exact: true })).toBeVisible();
	await expect(visits.getByText('Visits are kept 90 days.', { exact: false })).toBeVisible();

	const deleted = await page.request.delete(`/api/albums/${album.id}`);
	expect(deleted.status()).toBe(204);
});
