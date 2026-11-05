import { expect, test, type Browser, type Page } from '@playwright/test';
import { photo, signIn, users } from './helpers';

async function as(browser: Browser, baseURL: string | undefined, who?: keyof typeof users) {
	const context = await browser.newContext({ baseURL });
	const page = await context.newPage();
	if (who) await signIn(page, who);
	return page;
}

async function userId(page: Page) {
	const response = await page.request.get('/api/auth/status');
	return (await response.json()).user.id as string;
}

test.setTimeout(120000);

test('two users share an album, a third person uploads through a link, and rights hold', async ({
	browser,
	baseURL
}) => {
	const owner = await as(browser, baseURL, 'owner');
	const member = await as(browser, baseURL, 'member');
	const guest = await as(browser, baseURL);
	const title = `E2E album ${Date.now()}`;

	await owner.goto('/albums');
	await owner.getByRole('button', { name: 'New album' }).click();
	await owner.getByRole('textbox', { name: 'Name' }).fill(title);
	await owner.getByRole('button', { name: 'Create', exact: true }).click();
	await owner.getByRole('link', { name: title }).click();
	await expect(owner.getByRole('heading', { name: title })).toBeVisible();
	await expect(owner.getByText('This album is empty.', { exact: false })).toBeVisible();
	const albumId = owner.url().split('/').pop() as string;

	await owner.locator('input[type=file]').last().setInputFiles(photo('owner.jpg'));
	await expect(owner.locator('.tl-tile')).toHaveCount(1, { timeout: 40000 });

	// Not shared yet: the album does not exist for the other user.
	await member.goto(`/albums/${albumId}`);
	await expect(member.getByText('This album is not available.')).toBeVisible();

	const added = await owner.request.put(`/api/albums/${albumId}/members/${await userId(member)}`, {
		data: { role: 'viewer' }
	});
	expect(added.status()).toBe(204);

	// A viewer sees and comments, and has nothing to add or delete with.
	await member.goto('/albums');
	await member.getByRole('link', { name: title }).click();
	await expect(member.locator('.tl-tile')).toHaveCount(1);
	await expect(member.locator('label.btn', { hasText: 'Upload' })).toHaveCount(0);
	await expect(member.getByRole('button', { name: 'Delete' })).toHaveCount(0);
	const refused = await member.request.post(`/api/albums/${albumId}/assets/remove`, {
		data: { ids: ['00000000-0000-0000-0000-000000000000'] }
	});
	expect(refused.status()).toBe(403);

	await member.locator('.tl-tile').first().click();
	await expect(member.getByRole('button', { name: 'Delete' })).toHaveCount(0);
	await expect(member.getByRole('button', { name: 'Favorite' })).toHaveCount(0);
	await member.getByRole('button', { name: 'Comments and hearts' }).click();
	await member.getByRole('button', { name: 'Heart', exact: true }).click();
	await expect(member.getByRole('button', { name: 'Heart', exact: true })).toHaveAttribute(
		'aria-pressed',
		'true'
	);
	await member.getByRole('textbox', { name: 'Comment' }).fill('Looks great');
	await member.getByRole('button', { name: 'Send' }).click();
	await expect(member.getByText('Looks great')).toBeVisible();
	await member.goBack();

	// The owner sees it without reloading.
	await owner.locator('.tl-tile').first().click();
	await owner.getByRole('button', { name: 'Comments and hearts' }).click();
	await expect(owner.getByText('Looks great')).toBeVisible({ timeout: 15000 });
	await owner.goBack();

	// A new role reaches the open page by itself, and the contributor's photo reaches the owner.
	const promoted = await owner.request.put(
		`/api/albums/${albumId}/members/${await userId(member)}`,
		{ data: { role: 'contributor' } }
	);
	expect(promoted.status()).toBe(204);
	await expect(member.locator('label.btn', { hasText: 'Upload' })).toBeVisible({ timeout: 15000 });
	await member.locator('input[type=file]').last().setInputFiles(photo('member.jpg'));
	await expect(owner.locator('.tl-tile')).toHaveCount(2, { timeout: 50000 });

	// A third person, with no account, uploads through a link and sees nothing else.
	await owner.getByRole('button', { name: 'Links' }).click();
	await owner.getByLabel('Upload only').check();
	await owner.getByRole('button', { name: 'Create link' }).click();
	const address = owner.getByLabel('Link address');
	await expect(address).toBeVisible();
	const url = await address.inputValue();
	expect(url).toContain(new URL(baseURL as string).host);
	await owner.getByRole('button', { name: 'Close' }).click();

	await guest.setViewportSize({ width: 390, height: 800 });
	await guest.goto(url);
	await expect(guest.getByRole('heading', { name: title })).toBeVisible();
	await expect(guest.locator('.tl-tile')).toHaveCount(0);
	const noOverflow = await guest.evaluate(
		() => document.documentElement.scrollWidth <= window.innerWidth
	);
	expect(noOverflow, 'the page fits a phone').toBe(true);
	const token = url.split('/').pop();
	expect((await guest.request.get(`/api/public/${token}/buckets`)).status()).toBe(403);
	expect((await guest.request.get(`/api/albums/${albumId}`)).status()).toBe(401);
	await guest.locator('input[type=file]').setInputFiles(photo('guest.jpg'));
	await expect(guest.getByText('Sent: 1')).toBeVisible({ timeout: 15000 });
	await expect(owner.locator('.tl-tile')).toHaveCount(3, { timeout: 50000 });

	// Ending access works at once, for the member and for the link.
	const tile = await member.locator('.tl-tile img').first().getAttribute('src');
	const removed = await owner.request.delete(
		`/api/albums/${albumId}/members/${await userId(member)}`
	);
	expect(removed.status()).toBe(204);
	await expect(member.getByText('The connection to this album was lost.')).toBeVisible({
		timeout: 15000
	});
	const list = await owner.request.get(`/api/albums/${albumId}/links`);
	const [link] = await list.json();
	await owner.request.delete(`/api/albums/${albumId}/links/${link.id}`);
	await guest.reload();
	await expect(guest.getByText('This link is not available.')).toBeVisible();
	expect(tile).toBeTruthy();

	const deleted = await owner.request.delete(`/api/albums/${albumId}`);
	expect(deleted.status()).toBe(204);
});

test('a public link with a password shows the album, also on a phone', async ({
	browser,
	baseURL
}) => {
	const owner = await as(browser, baseURL, 'owner');
	const guest = await as(browser, baseURL);
	const title = `E2E public ${Date.now()}`;
	const album = await (await owner.request.post('/api/albums', { data: { title } })).json();
	await owner.goto(`/albums/${album.id}`);
	// A file chosen before the page is ready would be lost; a person cannot be that quick.
	await expect(owner.getByRole('heading', { name: title })).toBeVisible();
	await owner.waitForLoadState('networkidle');
	await owner.locator('input[type=file]').last().setInputFiles(photo('public.jpg'));
	await expect(owner.locator('.tl-tile')).toHaveCount(1, { timeout: 40000 });
	const created = await owner.request.post(`/api/albums/${album.id}/links`, {
		data: { password: 'open sesame', downloadLimit: 1 }
	});
	const { token } = await created.json();

	await guest.setViewportSize({ width: 390, height: 800 });
	await guest.goto(`/s/${token}`);
	await expect(guest.getByRole('heading', { name: title })).toHaveCount(0);
	await guest.getByLabel('Password', { exact: true }).fill('wrong');
	await guest.getByRole('button', { name: 'Open' }).click();
	await expect(guest.getByText('Wrong password.')).toBeVisible();
	await guest.getByLabel('Password', { exact: true }).fill('open sesame');
	await guest.getByRole('button', { name: 'Open' }).click();
	await expect(guest.getByRole('heading', { name: title })).toBeVisible();
	await expect(guest.locator('.tl-tile')).toHaveCount(1);
	await guest.locator('.tl-tile').first().click();
	await expect(guest.locator('.viewer-media').first()).toBeVisible();
	await expect(guest.getByRole('button', { name: 'Delete' })).toHaveCount(0);
	await expect(guest.getByRole('button', { name: 'Favorite' })).toHaveCount(0);
	await expect(guest.getByRole('link', { name: 'Download the original' })).toBeVisible();

	await owner.request.delete(`/api/albums/${album.id}`);
});

test('a link becomes a slideshow for a TV, once the administrator allows it', async ({
	page,
	browser
}) => {
	await signIn(page, 'owner');
	const albums = await page.request.post('/api/albums', { data: { title: 'E2E frame' } });
	const album = await albums.json();
	const made = await page.request.post(`/api/albums/${album.id}/links`, { data: {} });
	const { token } = await made.json();
	const baseURL = new URL(page.url() === 'about:blank' ? 'http://127.0.0.1:9852' : page.url())
		.origin;

	const guest = await browser.newContext({ baseURL });
	const tv = await guest.newPage();
	await tv.goto(`/kiosk/${token}`);
	await expect(tv.getByText(/nije uključio|has not turned/)).toBeVisible();

	const admin = await browser.newContext({ baseURL });
	await admin.request.post('/api/auth/login', {
		data: { email: 'e2e-admin@example.com', password: process.env.E2E_PASSWORD }
	});
	await admin.request.put('/api/admin/features/kiosk', { data: { enabled: true } });
	await tv.reload();
	await expect(tv.getByText(/Ovaj album je prazan|This album is empty/)).toBeVisible();
	await admin.request.put('/api/admin/features/kiosk', { data: { enabled: false } });
	await admin.close();
	await guest.close();
});
