import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

// The full resolution comes over the large preview. It must lie exactly on it, or the photo shows
// twice at two sizes, and the preview under it is hidden once it is in.
test('the full resolution covers the preview exactly, so a photo shows once', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const name = `layers-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=50')).json();
				id =
					list.items.find(
						(asset: { originalName: string; status: string }) =>
							asset.originalName === name && asset.status === 'ready'
					)?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');

	for (const size of [
		{ width: 1280, height: 800 },
		{ width: 390, height: 844 }
	]) {
		await page.setViewportSize(size);
		await page.goto(`/photos/${id}`);
		const full = page.locator('img.viewer-full.on');
		await expect(full).toBeVisible();
		const preview = page.locator('img.viewer-media:not(.viewer-full)');
		const [a, b] = [await full.boundingBox(), await preview.boundingBox()];
		expect(a, 'the full resolution has a box').toBeTruthy();
		for (const key of ['x', 'y', 'width', 'height'] as const) {
			expect(Math.abs(a![key] - b![key]), `${key} at ${size.width}px`).toBeLessThan(1);
		}
		await expect(preview).toHaveCSS('visibility', 'hidden');
	}
});

// One tap hides the bars, so the whole photo shows; the next brings them back. Two quick taps zoom
// and leave the bars as they were.
test('a tap on the photo hides the bars and the next one brings them back', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	const name = `hud-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=50')).json();
				id =
					list.items.find(
						(asset: { originalName: string; status: string }) =>
							asset.originalName === name && asset.status === 'ready'
					)?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');

	await page.setViewportSize({ width: 390, height: 844 });
	await page.goto(`/photos/${id}`);
	await expect(page.locator('img.viewer-full.on')).toBeVisible();
	const bar = page.locator('.viewer-top');
	await expect(bar).toHaveCSS('opacity', '1');
	const box = (await page.locator('.viewer-stage').boundingBox())!;
	const center = { x: box.x + box.width / 2, y: box.y + box.height / 2 };

	await page.mouse.click(center.x, center.y);
	await expect(bar).toHaveCSS('opacity', '0');
	await expect(bar).toHaveCSS('pointer-events', 'none');

	await page.mouse.click(center.x, center.y);
	await expect(bar).toHaveCSS('opacity', '1');

	await page.mouse.dblclick(center.x, center.y);
	await page.waitForTimeout(500);
	await expect(bar).toHaveCSS('opacity', '1');
});
