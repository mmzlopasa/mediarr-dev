import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
});

// The dev stack keeps a copy for itself: it invites, pairs by the code, and then removes both, so
// the demo is left as it was. Sending and bringing back a backup is tested in the server's tests.
test('an administrator invites another Mediarr and pairs with it by its code', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/admin/settings#keep');
	const card = page.locator('#keep');
	await expect(card.getByRole('heading', { name: 'I keep for others' })).toBeVisible();

	await card.getByLabel('For whom').fill('E2E relative');
	await card.getByLabel('At most (GB)').fill('1');
	// The server reaches itself on its own port inside the container.
	await card
		.getByLabel('The address the other server reaches you at')
		.fill('http://127.0.0.1:8080');
	await card.getByRole('button', { name: 'Invite' }).click();
	const invite = card.getByTestId('keep-invite');
	await expect(invite).toContainText('Code for E2E relative');
	await expect(invite.locator('svg')).toBeVisible();
	const code = (await invite.locator('code').textContent())?.trim() ?? '';
	expect(code.startsWith('mediarr-keep:')).toBe(true);

	const guests = card.getByRole('list', { name: 'I keep for others' });
	await expect(guests.locator('li', { hasText: 'E2E relative' })).toHaveAttribute(
		'data-guest',
		'invited'
	);

	await card.getByLabel('Code from the other Mediarr').fill(code);
	await card.getByRole('button', { name: 'Pair' }).click();
	const mine = card
		.getByRole('list', { name: 'My copy at others' })
		.locator('li', { hasText: 'E2E relative' });
	await expect(mine).toBeVisible();
	await expect(guests.locator('li', { hasText: 'E2E relative' })).toHaveAttribute(
		'data-guest',
		'active'
	);

	// The same code does not work twice.
	await card.getByLabel('Code from the other Mediarr').fill(code);
	await card.getByRole('button', { name: 'Pair' }).click();
	await expect(page.getByText(/used already|expired|wrong/)).toBeVisible();

	// Clean up: the copy, and the guest, whose name must be typed again.
	await mine.getByRole('button', { name: 'Remove' }).click();
	await expect(mine).toHaveCount(0);
	const guest = guests.locator('li', { hasText: 'E2E relative' });
	await guest.getByRole('button', { name: 'Remove' }).click();
	const confirm = guest.getByRole('button', { name: 'Delete the copy' });
	await expect(confirm).toBeDisabled();
	await guest.getByLabel(/to delete the copy/).fill('E2E relative');
	await confirm.click();
	await expect(card.getByText('E2E relative')).toHaveCount(0);
});
