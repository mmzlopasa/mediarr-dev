import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test('a 360° panorama is marked on its tile and turns in the viewer', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const name = `pano-${Date.now()}.jpg`;
	const buffer = readFileSync(join(import.meta.dirname, 'fixtures', 'pano.jpg'));
	await page.goto('/');
	await page.locator('main').waitFor();
	await page
		.locator('input[type=file]')
		.last()
		.setInputFiles({ name, mimeType: 'image/jpeg', buffer });
	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=200')).json();
				const found = list.items.find(
					(asset: { originalName: string; status: string; checksum: string }) =>
						asset.status === 'ready' && asset.originalName.startsWith('pano-')
				);
				id = found?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');
	const detail = await (await page.request.get(`/api/assets/${id}`)).json();
	expect(detail.projection).toBe('equirectangular');

	await page.goto(`/photos/${id}`);
	const pano = page.getByRole('img', { name: /360° panorama/ });
	await expect(pano).toBeVisible();
	await expect(pano.locator('canvas')).toBeAttached({ timeout: 20_000 });
	const toggle = page.getByRole('button', { name: '360° view' });
	await expect(toggle).toHaveAttribute('aria-pressed', 'true');
	await toggle.click();
	await expect(pano).toHaveCount(0);
	await expect(page.locator('.viewer-media:not(.under)').first()).toBeVisible();

	await page.goto('/');
	await expect(page.locator('.tl-pano').first()).toBeAttached({ timeout: 20_000 });
});
