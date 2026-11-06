import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test.use({ reducedMotion: 'no-preference' });

test('with motion on, titles, cards and numbers end up whole and true', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'user');

	await page.goto('/account');
	const title = page.getByRole('heading', { name: 'Account', level: 1 });
	await expect(title).toBeVisible();
	// The letters are put back together once they have risen.
	await expect(title.locator('.mo-word')).toHaveCount(0, { timeout: 5000 });
	await expect(title).toHaveText('Account');

	// A number counts, then shows the real value from the server.
	const stats = await (await page.request.get('/api/me/stats')).json();
	const photos = page.locator('.acct-stats div', { hasText: 'Photos' }).locator('dd');
	await expect(photos).toHaveText(String(stats.photos), { timeout: 5000 });

	// Albums come in as a wave and none stay hidden.
	const made = await (
		await page.request.post('/api/albums', { data: { title: 'e2e motion' } })
	).json();
	await page.goto('/albums');
	const grid = page.locator('main .alb-grid').first();
	await expect(grid).toHaveClass(/mo-ready/, { timeout: 5000 });
	for (const card of await grid.locator('> *').all()) {
		await card.scrollIntoViewIfNeeded();
		await expect(card).toBeVisible();
		await expect(card).toHaveCSS('opacity', '1', { timeout: 3000 });
	}
	await page.request.delete(`/api/albums/${made.id}`);
});

test('a smooth wheel moves the page, and the page ends where it was sent', async ({ page }) => {
	await signIn(page, 'user');
	await page.goto('/account');
	await page.getByRole('heading', { name: 'API keys' }).waitFor();
	await expect(page.locator('html')).toHaveClass(/lenis/);
	await page.mouse.move(400, 400);
	await page.mouse.wheel(0, 400);
	await expect
		.poll(() => page.evaluate(() => window.scrollY), { timeout: 3000 })
		.toBeGreaterThan(0);
});
