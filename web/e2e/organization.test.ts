import { expect, test, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { photo, signIn } from './helpers';

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
	await page.getByRole('button', { name: 'Back to Photos' }).click();
	await expect(page.getByText('The archive is empty.')).toBeVisible();
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
	await page.getByRole('button', { name: 'Back to Photos' }).click();
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

	await page.goto('/map');
	await expect(page.getByRole('heading', { name: 'Map' })).toBeVisible();
	await expect(page.getByText('Photos with a location: 1')).toBeVisible();
	await page.getByLabel('To date').fill('2020-01-01');
	await expect(page.getByText('Photos with a location: 0')).toBeVisible();
	await page.getByLabel('To date').fill('');
	await expect(page.getByText('Photos with a location: 1')).toBeVisible();

	const points = await (await page.request.get('/api/map/points')).json();
	const detail = await (await page.request.get(`/api/assets/${points.ids[0]}`)).json();
	expect(detail.city).toBe('Hvar');
	expect(detail.country).toBe('Croatia');
});
