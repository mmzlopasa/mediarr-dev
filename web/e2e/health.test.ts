import { expect, test } from '@playwright/test';

test('health endpoint answers through nginx', async ({ request }) => {
	const response = await request.get('/health');

	expect(response.status()).toBe(200);
	expect(await response.json()).toEqual({ status: 'ok' });
});

test('web client loads through nginx', async ({ page }) => {
	await page.goto('/');

	await expect(page.getByRole('heading', { name: /Fotke|Photos/ })).toBeVisible();
});
