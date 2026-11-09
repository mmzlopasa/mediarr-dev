import { expect, test } from '@playwright/test';

test("the server's name shows where people sign in", async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	// The name is the server's for everyone; changing it here would change other tests' pages, so
	// the server's answer is given a name instead. Saving it is tested on the server.
	await page.route('**/api/auth/methods', async (route) => {
		const response = await route.fetch();
		const methods = await response.json();
		await route.fulfill({ response, json: { ...methods, serverName: 'Kuća' } });
	});
	await page.goto('/login');
	await expect(page.getByText('Kuća', { exact: true })).toBeVisible();
});
