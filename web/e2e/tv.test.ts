import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

// The living room: the remote only has arrows, OK and back.
test('TV mode moves with the arrows, plays with OK and leaves with back', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'organizer');
	const photo = (id: string) => ({
		id,
		kind: 'photo',
		ratio: 1.5,
		isFavorite: false,
		localAt: '2024-07-01T10:00:00'
	});
	await page.route('**/api/memories*', (route) =>
		route.fulfill({
			json: [{ kind: 'on_this_day', year: 2024, title: '2024', items: [photo('m1'), photo('m2')] }]
		})
	);
	await page.route('**/api/albums?*', (route) =>
		route.fulfill({
			json: [
				{
					id: 'a1',
					title: 'Summer',
					description: '',
					role: 'owner',
					ownerId: 'o',
					ownerName: 'O',
					assetCount: 3,
					order: 'newest',
					isSmart: false,
					coverAssetId: 'c1'
				}
			]
		})
	);
	await page.route('**/api/albums/a1/buckets', (route) =>
		route.fulfill({ json: { buckets: [{ month: '2024-07', count: 3 }] } })
	);
	await page.route('**/api/albums/a1/buckets/2024-07', (route) =>
		route.fulfill({ json: { month: '2024-07', items: [photo('x1'), photo('x2'), photo('x3')] } })
	);
	await page.route('**/api/people', (route) =>
		route.fulfill({ json: { enabled: true, people: [] } })
	);

	await page.goto('/tv');
	await expect(page.getByRole('heading', { name: /On this day/, level: 1 })).toBeVisible();
	await expect(page.getByRole('button', { name: /On this day/ })).toBeFocused();
	await page.keyboard.press('ArrowDown');
	await expect(page.getByRole('button', { name: 'Summer' })).toBeFocused();
	await expect(page.getByRole('heading', { name: 'Summer', level: 1 })).toBeVisible();

	await page.keyboard.press('Enter');
	const show = page.getByRole('dialog', { name: 'Slideshow' });
	await expect(show).toContainText('1 / 3');
	await page.keyboard.press('ArrowRight');
	await expect(show).toContainText('2 / 3');
	await page.keyboard.press('Escape');
	await expect(show).toBeHidden();
	await expect(page.getByRole('button', { name: 'Summer' })).toBeFocused();

	await page.keyboard.press('Escape');
	await expect(page).toHaveURL(/\/$/);
});
