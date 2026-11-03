import { expect, test, type Page } from '@playwright/test';
import { join } from 'node:path';
import { signIn } from './helpers';

// The search for stacks and duplicates runs once a minute.
const WORKER_WAIT = 130000;
test.setTimeout(240000);
test.describe.configure({ mode: 'serial' });

const fixture = (name: string) => join(import.meta.dirname, 'fixtures', name);

async function upload(page: Page, names: string[]) {
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.waitForLoadState('networkidle');
	const before = await page.locator('.tl-tile').count();
	await page.locator('input[type=file]').last().setInputFiles(names.map(fixture));
	await expect(page.locator('.tl-tile')).toHaveCount(before + names.length, { timeout: 60000 });
}

test('similar photos are proposed, and removed only after confirming', async ({ page }) => {
	await signIn(page, 'stacker');
	await upload(page, ['similar-a.jpg', 'similar-b.jpg']);

	await expect(async () => {
		await page.goto('/duplicates');
		await expect(page.locator('.dup-item')).toHaveCount(2, { timeout: 3000 });
	}).toPass({ timeout: WORKER_WAIT, intervals: [5000] });
	await expect(page.locator('.dup-item.on')).toHaveCount(1);
	await expect(page.locator('.dup-item.on')).toContainText('similar-a.jpg');

	// Keeping both leaves nothing to remove.
	await page.locator('.dup-item:not(.on)').click();
	await expect(page.getByRole('button', { name: 'Move to the trash (0)' })).toBeDisabled();
	await page.locator('.dup-item', { hasText: 'similar-b.jpg' }).click();

	await page.getByRole('button', { name: 'Move to the trash (1)' }).click();
	await page.getByRole('dialog').getByRole('button', { name: 'Cancel' }).click();
	await expect(page.locator('.dup-item')).toHaveCount(2);

	await page.getByRole('button', { name: 'Move to the trash (1)' }).click();
	await page.getByRole('dialog').getByRole('button', { name: 'Move' }).click();
	await expect(page.getByText('No similar photos were found.')).toBeVisible();

	await page.goto('/trash');
	await expect(page.locator('.tl-tile')).toHaveCount(1);
});

test('a burst shows as one photo, and can be looked through and split', async ({ page }) => {
	await signIn(page, 'stacker');
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.waitForLoadState('networkidle');
	const before = await page.locator('.tl-tile').count();
	await page
		.locator('input[type=file]')
		.last()
		.setInputFiles(['burst0.jpg', 'burst1.jpg', 'burst2.jpg'].map(fixture));

	await expect(async () => {
		await page.goto('/');
		await expect(page.locator('.tl-tile')).toHaveCount(before + 1, { timeout: 3000 });
		await expect(page.locator('.tl-tile .tl-video small')).toHaveText('3', { timeout: 1000 });
	}).toPass({ timeout: WORKER_WAIT, intervals: [5000] });

	await page.locator('.tl-tile', { has: page.locator('.tl-video') }).click();
	const shots = page.locator('.viewer-stack-shot');
	await expect(shots).toHaveCount(3);
	await expect(page.getByRole('button', { name: 'Make it the main shot' })).toHaveCount(0);

	await shots.nth(2).click();
	await page.getByRole('button', { name: 'Make it the main shot' }).click();
	await expect(shots.first()).toHaveAttribute('aria-current', 'true');

	await page.getByRole('button', { name: 'Split the stack' }).click();
	await expect(shots).toHaveCount(0);
	await page.goto('/');
	await expect(page.locator('.tl-tile')).toHaveCount(before + 3);
});
