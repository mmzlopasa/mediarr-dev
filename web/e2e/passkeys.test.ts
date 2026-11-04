import { expect, test } from '@playwright/test';
import { users } from './helpers';

// A browser only offers passkeys on a secure address, and localhost counts as one.
const ORIGIN = 'http://localhost:9852';

test('a passkey is added, signs in, and is removed, with a software authenticator', async ({
	context,
	page
}) => {
	const cdp = await context.newCDPSession(page);
	await cdp.send('WebAuthn.enable');
	await cdp.send('WebAuthn.addVirtualAuthenticator', {
		options: {
			protocol: 'ctap2',
			transport: 'internal',
			hasResidentKey: true,
			hasUserVerification: true,
			isUserVerified: true,
			automaticPresenceSimulation: true
		}
	});
	const login = await context.request.post(`${ORIGIN}/api/auth/login`, {
		data: { email: users.stacker, password: process.env.E2E_PASSWORD }
	});
	expect(login.status()).toBe(200);

	await page.goto(`${ORIGIN}/account`);
	await page.getByLabel('Passkey name').fill('Laptop');
	await page.getByLabel('Your password').fill(process.env.E2E_PASSWORD as string);
	await page.getByRole('button', { name: 'Add a passkey' }).click();
	await expect(page.locator('.alb-list', { hasText: 'Laptop' })).toBeVisible();

	// Signed out, the passkey alone is enough.
	await context.clearCookies();
	await page.goto(`${ORIGIN}/login`);
	await page.getByRole('button', { name: 'Sign in with a passkey' }).click();
	await expect(page).not.toHaveURL(/login/);
	const status = await (await context.request.get(`${ORIGIN}/api/auth/status`)).json();
	expect(status.user.email).toBe(users.stacker);

	await page.goto(`${ORIGIN}/account`);
	await page
		.locator('.alb-list', { hasText: 'Laptop' })
		.getByRole('button', { name: 'Remove' })
		.click();
	await expect(page.locator('.alb-list', { hasText: 'Laptop' })).toHaveCount(0);
});

test('on an IP address passkeys are not offered, and signing in still works', async ({ page }) => {
	await page.goto('http://127.0.0.1:9852/login');
	await page.waitForLoadState('networkidle');
	await expect(page.getByRole('button', { name: 'Sign in with a passkey' })).toHaveCount(0);
});
