import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test('the language is chosen in the account menu, kept, and saved to the account', async ({
	page
}) => {
	await page.addInitScript(() => {
		if (!sessionStorage.getItem('seeded')) {
			sessionStorage.setItem('seeded', '1');
			localStorage.setItem('mediarr_lang', 'en');
		}
	});
	await signIn(page, 'importer');
	await page.goto('/');
	await expect(page.getByRole('heading', { name: 'Media' })).toBeVisible();
	try {
		await page.getByRole('button', { name: 'Account' }).click();
		await page.getByLabel('Language').selectOption('hr');
		await expect(page.getByRole('heading', { name: 'Mediji' })).toBeVisible();
		await expect(page.locator('html')).toHaveAttribute('lang', 'hr');

		// German is machine translated, and says so where it is chosen. The menu is still open.
		await expect(page.locator('#me-lang option', { hasText: 'maschinell' })).toHaveCount(1);
		await page.getByLabel('Jezik').selectOption('de');
		await expect(page.getByRole('heading', { name: 'Medien' })).toBeVisible();

		await page.reload();
		await expect(page.getByRole('heading', { name: 'Medien' })).toBeVisible();
		await expect
			.poll(async () => (await (await page.request.get('/api/auth/status')).json()).user.language)
			.toBe('de');
	} finally {
		// Other tests sign in as the same person.
		await page.request.patch('/api/me', { data: { language: 'en' } });
	}
});
