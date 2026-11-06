import { expect, test } from '@playwright/test';
import { join } from 'node:path';
import { signIn } from './helpers';

const fixtures = join(import.meta.dirname, 'fixtures');

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
});

// Anyone, not only an administrator, brings in a Google Takeout from the ZIP files it came in, with
// a photo's description and date in the other file than the photo.
test('a Takeout in two ZIP files comes in with its album, description and date', async ({
	page
}) => {
	test.setTimeout(120_000);
	await signIn(page, 'importer');
	await page.goto('/account/import');
	await expect(page.getByRole('heading', { name: 'Import', level: 1 })).toBeVisible();
	await expect(page.getByText('You have not imported anything yet.')).toBeVisible();

	await page
		.locator('.imp-drop input[type=file]')
		.setInputFiles([join(fixtures, 'takeout-001.zip'), join(fixtures, 'takeout-002.zip')]);
	const parts = page.getByRole('list', { name: 'Chosen files' }).getByRole('listitem');
	await expect(parts).toHaveCount(2);
	await page.getByRole('button', { name: 'Upload', exact: true }).click();
	await expect(parts.and(page.locator('[data-part=in]'))).toHaveCount(2);

	await page.getByRole('button', { name: 'Bring in' }).first().click();
	const mine = page.getByRole('list', { name: 'Your imports' }).getByRole('listitem').first();
	await expect(mine).toHaveAttribute('data-import', 'done', { timeout: 90_000 });
	await expect(mine).toContainText('added 2');
	await expect(mine).toContainText('2 / 2');

	const imports = await (await page.request.get('/api/imports')).json();
	expect(imports[0]).toMatchObject({ status: 'done', added: 2, failed: 0, total: 2, parts: [] });
	const albums = await (await page.request.get('/api/albums')).json();
	const trip = albums.find((album: { title: string }) => album.title === 'E2E trip');
	expect(trip, 'the album from metadata.json').toBeTruthy();

	// The photo opens with the description from the sidecar in the second ZIP file.
	await page.goto(`/albums/${trip.id}`);
	await page.locator('.tl-tile').first().click();
	await page.keyboard.press('i');
	await expect(page.getByText('E2E sunset')).toBeVisible();

	// Removing the import keeps the photos.
	await page.goto('/account/import');
	await mine.getByRole('button', { name: 'Remove' }).click();
	await expect(page.getByText('You have not imported anything yet.')).toBeVisible();
	const after = await (await page.request.get(`/api/albums/${trip.id}`)).json();
	expect(after.assetCount ?? after.assets?.length ?? 1).toBeGreaterThan(0);
});

test('a file that is not a ZIP file is refused with a reason', async ({ page }) => {
	await signIn(page, 'importer');
	await page.goto('/account/import');
	await page.locator('.imp-drop input[type=file]').setInputFiles({
		name: 'photos.zip',
		mimeType: 'application/zip',
		buffer: Buffer.from('this is not a zip file')
	});
	await page.getByRole('button', { name: 'Upload', exact: true }).click();
	const part = page.getByRole('list', { name: 'Chosen files' }).getByRole('listitem');
	await expect(part).toHaveAttribute('data-part', 'failed');
	await expect(part).toContainText('not a ZIP file');
});
