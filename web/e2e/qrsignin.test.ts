import { expect, test } from '@playwright/test';
import { signIn, users } from './helpers';

test('a phone signs in with the code from the account menu once it is allowed', async ({
	page,
	playwright
}) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'importer');
	await page.goto('/');
	await page.getByRole('button', { name: 'Account' }).click();
	await page.getByRole('button', { name: 'Sign in on a phone' }).click();
	const dialog = page.getByRole('dialog', { name: 'Sign in on a phone' });
	await expect(dialog.getByRole('img', { name: 'Sign-in QR code' }).locator('svg')).toBeVisible();
	const code = (await dialog.getByTestId('qr-code').textContent())?.trim() ?? '';
	expect(code).toMatch(/^[2-9A-Z]{4}-[2-9A-Z]{4}$/);

	// The phone hands in the code it scanned, then waits for this screen to answer.
	const phone = await playwright.request.newContext({
		baseURL: test.info().project.use.baseURL
	});
	const redeemed = await phone.post('/api/auth/qr/redeem', {
		data: { code, device: 'Pixel 9 (e2e)' }
	});
	expect(redeemed.status()).toBe(200);
	const { ticket } = await redeemed.json();
	const ask = dialog.getByRole('alertdialog', { name: 'Allow sign-in on Pixel 9 (e2e)?' });
	await expect(ask).toBeVisible();
	const waiting = phone.post('/api/auth/qr/wait', { data: { ticket } });
	await ask.getByRole('button', { name: 'Allow' }).click();
	const signedIn = await waiting;
	expect(signedIn.status()).toBe(200);
	expect((await signedIn.json()).email).toBe(users.importer);
	await expect(dialog.getByText('Pixel 9 (e2e) is signed in')).toBeVisible();

	// The phone has its own session now; it signs out so no session is left behind.
	const status = await (await phone.get('/api/auth/status')).json();
	expect(status.user.email).toBe(users.importer);
	await phone.post('/api/auth/logout');
	await phone.dispose();
});
