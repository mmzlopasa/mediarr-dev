import { expect, test, type Page } from '@playwright/test';
import { photo, signIn } from './helpers';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
});

async function uploaded(page: Page, name: string) {
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
	return id;
}

// A page that is not there and a server that is not there are different things to say.
test('the error page tells a missing page from a server that is unavailable', async ({ page }) => {
	await signIn(page, 'importer');
	await page.goto('/no-such-section/really-not');
	await expect(page.getByText('This page does not exist.')).toBeVisible();
	await expect(page.getByRole('button', { name: 'Try again' })).toHaveCount(0);

	await page.route('**/api/auth/status', (route) =>
		route.fulfill({ status: 503, contentType: 'application/json', body: '{}' })
	);
	await page.goto('/');
	await expect(page.getByText(/The server is not available right now/)).toBeVisible();
	await expect(page.getByText('This page does not exist.')).toHaveCount(0);
	await page.unroute('**/api/auth/status');
	await page.getByRole('button', { name: 'Try again' }).click();
	await expect(page.getByText(/The server is not available right now/)).toHaveCount(0);
});

// A public link the server cannot read right now says so and can be tried again, instead of
// loading forever.
test('a public link that fails to load says why and offers to try again', async ({ page }) => {
	await page.route('**/api/public/broken-token', (route) =>
		route.fulfill({ status: 503, contentType: 'application/json', body: '{}' })
	);
	await page.goto('/s/broken-token');
	await expect(page.getByText(/The server is not available right now/)).toBeVisible();
	await page.unroute('**/api/public/broken-token');
	await page.getByRole('button', { name: 'Try again' }).click();
	await expect(page.getByText(/The server is not available right now/)).toHaveCount(0);
});

// Esc closes only what is on top: a slideshow or a menu over the viewer, not the viewer too.
test('Escape closes only the overlay on top of the viewer, and focus stays in it', async ({
	page
}) => {
	await signIn(page, 'importer');
	const name = `escape-${Date.now()}.jpg`;
	const id = await uploaded(page, name);
	await page.goto(`/photos/${id}`);
	const viewer = page.getByRole('dialog', { name });
	await expect(viewer).toBeVisible();

	await viewer.getByRole('button', { name: 'Slideshow' }).click();
	const show = page.getByRole('dialog', { name: 'Slideshow' });
	await expect(show).toBeVisible();
	await page.keyboard.press('Escape');
	await expect(show).toHaveCount(0);
	await expect(viewer).toBeVisible();
	await expect(page).toHaveURL(new RegExp(`/photos/${id}$`));

	// Details open over the photo close first; the viewer stays.
	await viewer.getByRole('button', { name: 'Details' }).click();
	await expect(viewer.getByRole('complementary', { name: 'Details' })).toBeVisible();
	await page.keyboard.press('Escape');
	await expect(viewer.getByRole('complementary', { name: 'Details' })).toHaveCount(0);
	await expect(viewer).toBeVisible();

	// Tab goes round the viewer's own controls and never reaches the page behind it.
	for (let step = 0; step < 30; step += 1) {
		await page.keyboard.press('Tab');
		expect(
			await page.evaluate(() => !!document.activeElement?.closest('.viewer')),
			`focus after ${step + 1} Tab presses`
		).toBe(true);
	}

	await page.keyboard.press('Escape');
	await expect(viewer).toHaveCount(0);
});
