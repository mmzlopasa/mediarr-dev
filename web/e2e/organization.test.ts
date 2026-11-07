import { expect, test, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { photo, signIn, users, settledTiles } from './helpers';

test.setTimeout(90000);
test.describe.configure({ mode: 'serial' });

async function upload(page: Page, name: string) {
	await page.goto('/');
	await page.locator('main').waitFor();
	// The first look at the server has to finish, or there is nothing to count yet.
	await page.waitForLoadState('networkidle');
	const before = await settledTiles(page);
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
	await expect(page.locator('.viewer-media:not(.under)').first()).toBeVisible();
	await page.goBack();
	await select(page);
	await page.getByRole('button', { name: 'Back to Media' }).click();
	await expect(page.getByText('The vault is empty.')).toBeVisible();
});

test('a face is corrected from the details of a photo', async ({ page }) => {
	await signIn(page, 'organizer');
	await upload(page, 'face.jpg');
	const face = '00000000-0000-4000-8000-000000000002';
	const person = '00000000-0000-4000-8000-000000000003';
	await page.route('**/api/assets/*/faces', (route) =>
		route.fulfill({
			json: { faces: [{ id: face, x1: 0.1, y1: 0.1, x2: 0.4, y2: 0.4 }] }
		})
	);
	await page.route('**/api/people', (route) =>
		route.fulfill({
			json: {
				enabled: true,
				people: [{ id: person, name: 'Ana', hidden: false, assetCount: 2 }]
			}
		})
	);
	const sent: { method: string; body: unknown }[] = [];
	await page.route(`**/api/faces/${face}`, async (route) => {
		sent.push({ method: route.request().method(), body: route.request().postDataJSON() });
		await route.fulfill({ status: 204 });
	});
	await page.locator('.tl-tile').first().click();
	await page.getByRole('button', { name: 'Details' }).click();
	await page.getByLabel('Who this is').selectOption(person);
	await expect.poll(() => sent[0]).toEqual({ method: 'PUT', body: { personId: person } });
	await page.getByLabel('Who this is').selectOption('new');
	await page.getByLabel('Name', { exact: true }).fill('Teta Mara');
	await page
		.getByRole('complementary', { name: 'Details' })
		.getByRole('button', { name: 'Save' })
		.click();
	await expect.poll(() => sent[1]).toEqual({ method: 'PUT', body: { name: 'Teta Mara' } });
	await page.getByRole('button', { name: 'Not a person' }).click();
	await expect.poll(() => sent[2]?.method).toBe('DELETE');
});

test('a photo gets a new date, place and description, and can go back to its file', async ({
	page
}) => {
	await signIn(page, 'organizer');
	await upload(page, 'facts.jpg');
	await page.locator('.tl-tile').first().click();
	await page.getByRole('button', { name: 'Details' }).click();
	await page.getByRole('button', { name: 'Edit details' }).click();
	const dialog = page.getByRole('dialog', { name: 'Edit details' });
	await dialog.getByLabel('Date and time').fill('2001-02-03T04:05');
	await dialog.getByLabel('Latitude').fill('45.8');
	await dialog.getByLabel('Longitude').fill('15.97');
	await dialog.getByLabel('Description').fill('At the lake');
	await dialog.getByRole('button', { name: 'Save' }).click();
	const details = page.getByRole('complementary', { name: 'Details' });
	await expect(details.getByText('At the lake')).toBeVisible();
	// The date is in the panel's title line and in its row.
	await expect(details.getByText('2001').first()).toBeVisible();
	await details.getByRole('button', { name: 'Edit details' }).click();
	await expect(dialog.getByLabel('Latitude')).toHaveValue('45.8');
	await dialog.getByRole('button', { name: 'Use what the file says' }).click();
	await expect(dialog).toBeHidden();
});

test('Explore shows people, places and memories, and each leads further', async ({ page }) => {
	await signIn(page, 'organizer');
	const cover = '00000000-0000-4000-8000-000000000004';
	await page.route('**/api/explore/places', (route) =>
		route.fulfill({
			json: { places: [{ name: 'Hvar', country: 'HR', assetCount: 3, coverId: cover }] }
		})
	);
	await page.goto('/explore');
	await expect(page.getByRole('heading', { name: 'Explore', level: 1 })).toBeVisible();
	await expect(page.getByRole('heading', { name: 'People' })).toBeVisible();
	await expect(page.getByRole('heading', { name: 'Memories' })).toBeVisible();
	await page.getByRole('link', { name: /Hvar/ }).click();
	await expect(page).toHaveURL(/\/search\?q=Hvar/);
});

test('Explore says when no photo has a place yet', async ({ page }) => {
	await signIn(page, 'organizer');
	await page.route('**/api/explore/places', (route) => route.fulfill({ json: { places: [] } }));
	await page.goto('/explore');
	await expect(page.getByText('No photos with a place yet.')).toBeVisible();
});

test('stars are given, taken away, and the sidecar can be downloaded', async ({ page }) => {
	await signIn(page, 'organizer');
	await upload(page, 'stars.jpg');
	await page.locator('.tl-tile').first().click();
	await page.getByRole('button', { name: 'Details' }).click();
	const four = page.getByRole('button', { name: '4 of 5 stars' });
	await four.click();
	await expect(four).toHaveAttribute('aria-pressed', 'true');
	await page.reload();
	await page.getByRole('button', { name: 'Details' }).click();
	await expect(four).toHaveAttribute('aria-pressed', 'true');
	await four.click();
	await expect(four).toHaveAttribute('aria-pressed', 'false');
	const download = page.waitForEvent('download');
	await page.getByRole('link', { name: 'Download XMP' }).click();
	expect((await download).suggestedFilename()).toMatch(/stars.*\.xmp$/);
});

test('a date of birth is saved with the person', async ({ page }) => {
	await signIn(page, 'organizer');
	const person = '00000000-0000-4000-8000-000000000001';
	await page.route('**/api/people', (route) =>
		route.fulfill({
			json: {
				enabled: true,
				people: [{ id: person, name: 'Ana', hidden: false, assetCount: 2, birthDate: '1990-05-17' }]
			}
		})
	);
	let saved: unknown;
	await page.route(`**/api/people/${person}`, async (route) => {
		saved = route.request().postDataJSON();
		await route.fulfill({ status: 204 });
	});
	await page.goto(`/people/${person}`);
	const born = page.getByLabel('Date of birth');
	await expect(born).toHaveValue('1990-05-17');
	await born.fill('1991-06-18');
	await page.getByRole('button', { name: 'Save' }).click();
	await expect.poll(() => saved).toEqual({ name: 'Ana', birthDate: '1991-06-18' });
});

test('a tag groups photos', async ({ page }) => {
	await signIn(page, 'organizer');
	await upload(page, 'tag.jpg');
	const name = `Tag ${Date.now()}`;
	await select(page);
	await page.getByRole('button', { name: 'Add a tag' }).click();
	await page.getByLabel('New tag').fill(name);
	await page.getByRole('button', { name: 'Create and add' }).click();
	await expect(page.getByText(/^Tagged: 1/)).toBeVisible();
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
	const before = await settledTiles(page);
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
	await expect(page.getByRole('list', { name: 'Filters in this search' })).toContainText(
		/2024 – .*2024/
	);
	await page.getByRole('button', { name: 'Open' }).click();
	await expect(page.locator('.viewer-media:not(.under)').first()).toBeVisible();
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
		.locator('.set-list li', { hasText: 'e2e script' })
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
