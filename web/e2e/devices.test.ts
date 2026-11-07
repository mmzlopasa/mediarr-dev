import { expect, test } from '@playwright/test';
import { photo, signIn } from './helpers';

test('a phone that backs up shows what the server counts as safe, and its owner can remove it', async ({
	page
}) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'member');
	const name = `device-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	let checksum = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=200')).json();
				const found = list.items.find(
					(asset: { originalName: string }) => asset.originalName === name
				);
				checksum = found?.checksum ?? '';
				return checksum.length;
			},
			{ timeout: 60_000 }
		)
		.toBe(64);

	// The phone says two files are safe; the server has only one of them.
	const device = crypto.randomUUID();
	const deviceName = `Test phone ${Date.now()}`;
	const reported = await page.request.put(`/api/me/backup-devices/${device}`, {
		data: {
			name: deviceName,
			platform: 'android',
			appVersion: '0.8.0',
			pending: 3,
			working: 0,
			verified: 2,
			failed: 1,
			failures: [{ name: 'IMG_0042.HEIC', reason: 'The file could not be read.' }],
			checksums: [checksum, 'ab'.repeat(32)],
			replace: true
		}
	});
	expect(reported.status()).toBe(200);

	await page.goto('/account/devices');
	const row = page.locator(`[data-device="${deviceName}"]`);
	await expect(row).toBeVisible();
	await expect(row).toContainText('1 files confirmed by the server');
	await expect(row).toContainText('of 2 the device sent');
	await expect(row).toContainText('Needs a look');
	await row.getByRole('button', { name: 'What is missing' }).click();
	await expect(row).toContainText('IMG_0042.HEIC');
	await expect(row).toContainText('was deleted from the server');

	await page.getByLabel('Warn after').selectOption('7');
	await expect(page.getByText('Saved.')).toBeVisible();
	const list = await (await page.request.get('/api/me/backup-devices')).json();
	expect(list.quietDays).toBe(7);
	await page.request.put('/api/me/backup-devices/quiet-days', { data: { days: 3 } });

	page.once('dialog', (dialog) => dialog.accept());
	await row.getByRole('button', { name: 'Remove' }).click();
	await expect(row).toHaveCount(0);
});

test('the administrator sees every user’s devices', async ({ page, browser }) => {
	const member = await browser.newContext();
	const phone = await member.newPage();
	await signIn(phone, 'member');
	const device = crypto.randomUUID();
	const deviceName = `Family phone ${Date.now()}`;
	const reported = await phone.request.put(`/api/me/backup-devices/${device}`, {
		data: {
			name: deviceName,
			platform: 'ios',
			appVersion: '0.8.0',
			pending: 0,
			working: 0,
			verified: 0,
			failed: 0
		}
	});
	expect(reported.status()).toBe(200);

	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	await page.goto('/admin/devices');
	const row = page.locator(`[data-device="${deviceName}"]`);
	await expect(row).toBeVisible();
	await expect(row).toContainText('e2e-member@example.com');
	await expect(row).toContainText('iOS');

	await phone.request.delete(`/api/me/backup-devices/${device}`);
	await member.close();
});
