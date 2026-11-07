import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test('the administrator sees the snapshots kept before upgrades, and how to go back', async ({
	page
}) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	const listed = await (await page.request.get('/api/admin/upgrade-snapshots')).json();
	await page.goto('/admin/health');
	const card = page.locator('#snapshots');
	await expect(card.getByText('Snapshots before upgrades')).toBeVisible();
	if (listed.length === 0) {
		await expect(card).toContainText('No snapshots yet.');
	} else {
		await expect(card.locator(`[data-snapshot="${listed[0].name}"]`)).toContainText(
			listed[0].toVersion
		);
		await expect(card).toContainText('docker compose run --rm server rollback');
	}
});

test('people who are not administrators cannot see the snapshots', async ({ page }) => {
	await signIn(page, 'user');
	const response = await page.request.get('/api/admin/upgrade-snapshots');
	expect(response.status()).toBe(403);
});
