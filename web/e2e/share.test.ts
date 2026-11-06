import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

// The browser's share sheet cannot be opened in a test, so it is stood in for, and what it is handed
// is checked.
test('a photo is handed to the share sheet as its original or smaller', async ({ page }) => {
	await page.addInitScript(() => {
		localStorage.setItem('mediarr_lang', 'en');
		const shared: { name: string; type: string; size: number }[][] = [];
		(window as unknown as { shared: typeof shared }).shared = shared;
		Object.assign(navigator, {
			canShare: () => true,
			share: async ({ files }: { files: File[] }) => {
				shared.push(files.map((file) => ({ name: file.name, type: file.type, size: file.size })));
			}
		});
	});
	await signIn(page, 'importer');
	const name = `share-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=50')).json();
				const found = list.items.find(
					(asset: { originalName: string; status: string }) =>
						asset.originalName === name && asset.status === 'ready'
				);
				id = found?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');

	await page.goto(`/photos/${id}`);
	await page.getByRole('button', { name: 'Share' }).click();
	await page.getByRole('menuitem', { name: /Smaller, for messages/ }).click();
	await expect
		.poll(() => page.evaluate(() => (window as unknown as { shared: unknown[] }).shared.length))
		.toBe(1);
	const [files] = await page.evaluate(
		() => (window as unknown as { shared: { name: string; type: string }[][] }).shared
	);
	expect(files[0].type).toBe('image/jpeg');
	expect(files[0].name.endsWith('.jpg')).toBe(true);

	await page.getByRole('button', { name: 'Share' }).click();
	await page.getByRole('menuitem', { name: /Original/ }).click();
	await expect
		.poll(() => page.evaluate(() => (window as unknown as { shared: unknown[] }).shared.length))
		.toBe(2);
});
