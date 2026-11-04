import { expect, test, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { photo, signIn, users } from './helpers';

test.setTimeout(90000);
test.describe.configure({ mode: 'serial' });

async function upload(page: Page, name: string) {
	await page.goto('/');
	await page.locator('main').waitFor();
	// The first look at the server has to finish, or there is nothing to count yet.
	await page.waitForLoadState('networkidle');
	const before = await page.locator('.tl-tile').count();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	await expect(page.locator('.tl-tile')).toHaveCount(before + 1, { timeout: 40000 });
	return before + 1;
}

async function select(page: Page) {
	await page
		.locator('.tl-tile')
		.first()
		.click({ modifiers: ['Control'] });
}

test('a deleted photo goes to the trash, comes back, and can be deleted for good', async ({
	page
}) => {
	await signIn(page, 'organizer');
	const count = await upload(page, 'trash.jpg');
	await select(page);
	await page.getByRole('button', { name: 'Delete' }).click();
	await expect(page.getByText('stay for 30 days')).toBeVisible();
	await page.getByRole('dialog').getByRole('button', { name: 'Delete' }).click();
	await expect(page.locator('.tl-tile')).toHaveCount(count - 1);

	await page.goto('/trash');
	await expect(page.getByRole('heading', { name: 'Trash' })).toBeVisible();
	await expect(page.locator('.tl-tile')).toHaveCount(1);
	await page.locator('.tl-tile img').first().waitFor();
	await select(page);
	await page.getByRole('button', { name: 'Restore' }).click();
	await expect(page.getByText('The trash is empty.')).toBeVisible();

	await page.goto('/');
	await expect(page.locator('.tl-tile')).toHaveCount(count);
	await select(page);
	await page.getByRole('button', { name: 'Delete' }).click();
	await page.getByRole('dialog').getByRole('button', { name: 'Delete' }).click();
	await page.goto('/trash');
	await expect(page.locator('.tl-tile')).toHaveCount(1);
	await page.getByRole('button', { name: 'Empty the trash' }).click();
	await page
		.getByRole('dialog', { name: 'Empty the trash?' })
		.getByRole('button', { name: 'Empty the trash' })
		.click();
	await expect(page.getByText('The trash is empty.')).toBeVisible();
});

test('the archive takes a photo off the timeline and gives it back', async ({ page }) => {
	await signIn(page, 'organizer');
	const count = await upload(page, 'archive.jpg');
	await select(page);
	await page.getByRole('button', { name: 'Archive' }).click();
	await expect(page.locator('.tl-tile')).toHaveCount(count - 1);
	await page.goto('/archive');
	await expect(page.locator('.tl-tile')).toHaveCount(1);
	await select(page);
	await page.getByRole('button', { name: 'Back to Media' }).click();
	await expect(page.getByText('The archive is empty.')).toBeVisible();
});

test('a starred photo is in Favorites until the star is taken away', async ({ page }) => {
	await signIn(page, 'organizer');
	await upload(page, 'favorite.jpg');
	await select(page);
	await page
		.getByRole('button', { name: /favorite/i })
		.first()
		.click();
	await page.goto('/favorites');
	await expect(page.locator('.tl-tile')).toHaveCount(1);
	await select(page);
	await page.getByRole('button', { name: 'Remove from favorites' }).click();
	await expect(page.getByText('No favorites yet.', { exact: false })).toBeVisible();
});

test('the library uses the whole width of a very wide screen', async ({ page }) => {
	await signIn(page, 'organizer');
	await page.setViewportSize({ width: 3440, height: 1440 });
	await page.goto('/');
	await page.locator('.tl').waitFor();
	const width = await page.locator('.tl').evaluate((element) => element.clientWidth);
	expect(width).toBeGreaterThan(2800);
});

test('the vault hides a photo until the PIN opens it', async ({ page }) => {
	await signIn(page, 'organizer');
	const count = await upload(page, 'vault.jpg');

	// Without a PIN, the app asks for one first.
	await select(page);
	await page.getByRole('button', { name: 'Move to the vault' }).click();
	await expect(page).toHaveURL(/\/vault$/);
	await expect(page.getByText('not encrypted')).toBeVisible();
	await page.getByLabel('PIN').fill('12');
	await page.getByRole('button', { name: 'Set PIN' }).click();
	await expect(page.getByText('between 4 and 12 digits')).toBeVisible();
	await page.getByLabel('PIN').fill('4321');
	await page.getByRole('button', { name: 'Set PIN' }).click();
	await expect(page.getByText('The vault is empty.')).toBeVisible();
	await page.getByRole('button', { name: 'Lock' }).click();

	await page.goto('/');
	await expect(page.locator('.tl-tile')).toHaveCount(count);
	await select(page);
	await page.getByRole('button', { name: 'Move to the vault' }).click();
	await expect(page.locator('.tl-tile')).toHaveCount(count - 1);

	await page.goto('/vault');
	await expect(page.locator('.tl-tile')).toHaveCount(0);
	await page.getByLabel('PIN').fill('0000');
	await page.getByRole('button', { name: 'Unlock' }).click();
	await expect(page.getByText('Wrong PIN.')).toBeVisible();
	await page.getByLabel('PIN').fill('4321');
	await page.getByRole('button', { name: 'Unlock' }).click();
	await expect(page.locator('.tl-tile')).toHaveCount(1);
	await page.locator('.tl-tile').first().click();
	await expect(page.locator('.viewer-media').first()).toBeVisible();
	await page.goBack();
	await select(page);
	await page.getByRole('button', { name: 'Back to Media' }).click();
	await expect(page.getByText('The vault is empty.')).toBeVisible();
});

test('a tag groups photos', async ({ page }) => {
	await signIn(page, 'organizer');
	await upload(page, 'tag.jpg');
	const name = `Tag ${Date.now()}`;
	await select(page);
	await page.getByRole('button', { name: 'Add a tag' }).click();
	await page.getByLabel('New tag').fill(name);
	await page.getByRole('button', { name: 'Create and add' }).click();
	await page.goto('/albums');
	await page.getByRole('link', { name: 'Tags', exact: true }).click();
	await page.getByRole('link', { name }).click();
	await expect(page.getByRole('heading', { name })).toBeVisible();
	await expect(page.locator('.tl-tile')).toHaveCount(1);
	await select(page);
	await page.getByRole('button', { name: 'Remove the tag' }).click();
	await page.reload();
	await expect(page.locator('.tl-tile')).toHaveCount(0);
	await page.goto('/tags');
	await page.getByRole('button', { name: 'Delete' }).last().click();
});

test('a photo with a location appears on the map under its place name', async ({ page }) => {
	await signIn(page, 'organizer');
	const gps = readFileSync(join(import.meta.dirname, 'fixtures', 'gps.jpg'));
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.waitForLoadState('networkidle');
	const before = await page.locator('.tl-tile').count();
	await page
		.locator('input[type=file]')
		.last()
		.setInputFiles({
			name: 'gps.jpg',
			mimeType: 'image/jpeg',
			buffer: Buffer.concat([gps, Buffer.from(String(Math.random()))])
		});
	await expect(page.locator('.tl-tile')).toHaveCount(before + 1, { timeout: 40000 });

	const problems: string[] = [];
	page.on('console', (message) => {
		if (message.type() === 'error' && message.text().includes('Worker')) {
			problems.push(message.text());
		}
	});
	await page.goto('/map');
	await expect(page.getByRole('heading', { name: 'Map' })).toBeVisible();
	await expect(page.getByText('With a location: 1')).toBeVisible();
	await page.getByLabel('To date').fill('2020-01-01');
	await expect(page.getByText('With a location: 0')).toBeVisible();
	await page.getByLabel('To date').fill('');
	await expect(page.getByText('With a location: 1')).toBeVisible();

	await expect(page.locator('canvas.maplibregl-canvas')).toBeVisible();
	expect(problems, 'the map needs its worker').toEqual([]);

	const points = await (await page.request.get('/api/map/points')).json();
	const detail = await (await page.request.get(`/api/assets/${points.ids[0]}`)).json();
	expect(detail.city).toBe('Hvar');
	expect(detail.country).toBe('Croatia');
});

test('search answers, shows its filters and says when something is not found', async ({ page }) => {
	await signIn(page, 'organizer');
	await page.goto('/search');
	await expect(page.getByRole('heading', { name: 'Search' })).toBeVisible();
	await expect(page.getByText('Describe what you are looking for')).toBeVisible();
	await page.getByRole('textbox', { name: 'What are you looking for?' }).fill('gps.jpg 2024');
	await page.getByRole('main').getByRole('button', { name: 'Search' }).click();
	await expect(page).toHaveURL(/\/search\?q=/);
	await expect(page.getByRole('button', { name: 'Open' })).toHaveCount(1);
	await expect(page.getByText('2024-01-01 – 2024-12-31')).toBeVisible();
	await page.getByRole('button', { name: 'Open' }).click();
	await expect(page.locator('.viewer-media').first()).toBeVisible();
	await page.goBack();
	await page.goto('/search?q=2001');
	await expect(page.getByText('Nothing was found.')).toBeVisible();
});

test('the people page lists no one before any face is known', async ({ page }) => {
	await signIn(page, 'organizer');
	await page.goto('/people');
	await expect(page.getByRole('heading', { name: 'People' })).toBeVisible();
	await expect(page.getByText('No people recognised yet.')).toBeVisible();
});

test('a memory plays as a story and becomes a video', async ({ page }) => {
	await signIn(page, 'organizer');
	await page.goto('/memories');
	await expect(page.getByRole('heading', { name: 'Memories' })).toBeVisible();

	// The photo with a location was taken on 15 June 2024, so this looks at that day a year later.
	await page.route('**/api/memories?*', (route) => {
		const url = new URL(route.request().url());
		url.searchParams.set('date', '2025-06-15');
		return route.continue({ url: url.href });
	});
	await page.reload();
	await page.getByRole('button', { name: /On this day/ }).click();
	const story = page.getByRole('dialog');
	await expect(story.locator('img')).toBeVisible();
	await story.getByRole('button', { name: 'Make a video' }).click();
	await expect(story.getByRole('link', { name: 'Download the video' })).toBeVisible({
		timeout: 60000
	});
	const address = await story
		.getByRole('link', { name: 'Download the video' })
		.getAttribute('href');
	const video = await page.request.get(address as string);
	expect(video.status()).toBe(200);
	expect((await video.body()).length).toBeGreaterThan(1000);
	await story.getByRole('button', { name: 'Close' }).click();
	await expect(story).toHaveCount(0);
});

test('a key is created with chosen rights, shown once, and revoked', async ({ page }) => {
	await signIn(page, 'organizer');
	await page.goto('/account');
	await page.getByLabel('Key name').fill('e2e script');
	await page.getByRole('button', { name: 'Create a key' }).click();
	const key = await page.getByTestId('new-key').textContent();
	expect(key?.length).toBeGreaterThan(20);

	// A key given only the right to read cannot change anything.
	const headers = { 'X-Api-Key': key as string };
	const fresh = await page
		.context()
		.browser()!
		.newContext({ baseURL: new URL(page.url()).origin });
	const read = await fresh.request.get('/api/timeline/buckets', { headers });
	expect(read.status()).toBe(200);
	const write = await fresh.request.post('/api/albums', { headers, data: { title: 'x' } });
	expect(write.status()).toBe(403);

	await page.reload();
	await expect(page.getByText('e2e script')).toBeVisible();
	await expect(page.getByText(key as string)).toHaveCount(0);
	await page
		.locator('.alb-list', { hasText: 'e2e script' })
		.getByRole('button', { name: 'Revoke' })
		.click();
	await expect(page.getByText('e2e script')).toHaveCount(0);
	const after = await fresh.request.get('/api/timeline/buckets', { headers });
	expect(after.status()).toBe(401);
	await fresh.close();
});

test('a family shares by rules, and only once it is turned on', async ({ page, browser }) => {
	test.setTimeout(120000);
	await signIn(page, 'organizer');
	await page.goto('/family');
	await expect(page.getByText(/nije uključio|has not turned/)).toBeVisible();

	const origin = new URL(page.url()).origin;
	const admin = await browser.newContext({ baseURL: origin });
	await admin.request.post('/api/auth/login', {
		data: { email: users.admin, password: process.env.E2E_PASSWORD }
	});
	await admin.request.put('/api/admin/features/family', { data: { enabled: true } });
	const all = await (await admin.request.get('/api/admin/users')).json();
	const me = all.find((user: { email: string }) => user.email === users.organizer);
	await admin.request.put(`/api/admin/family/${me.id}`, { data: {} });

	await page.reload();
	await page.getByLabel(/Naziv pravila|Rule name/).fill('Since 2000');
	await page.getByLabel(/^(Od datuma|From date)/).fill('2000-01-01');
	await page.getByRole('button', { name: /Dijeli s obitelji|Share with the family/ }).click();
	await expect(page.locator('.alb-list', { hasText: 'Since 2000' })).toBeVisible();
	await page.locator('.alb-list', { hasText: 'Since 2000' }).getByRole('button').click();
	await expect(page.locator('.alb-list', { hasText: 'Since 2000' })).toHaveCount(0);

	await admin.request.delete(`/api/admin/family/${me.id}`);
	await admin.request.put('/api/admin/features/family', { data: { enabled: false } });
	await admin.close();
});
