import { expect, test } from '@playwright/test';
import { join } from 'node:path';
import { signIn } from './helpers';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
});

test('a person changes their name and picture, and removes the picture', async ({ page }) => {
	await signIn(page, 'importer');
	await page.goto('/account');
	const card = page.locator('#profile');
	await expect(card.getByLabel('Name')).not.toHaveValue('');

	await card.getByLabel('Name').fill('E2E Profile');
	// An email change asks for the password; a name alone does not.
	await expect(card.getByLabel(/Current password/)).toHaveCount(0);
	await card.getByRole('button', { name: 'Save' }).click();
	await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
	await expect(page.locator('.ph p')).toContainText('E2E Profile');

	await card
		.getByLabel('Choose a profile picture')
		.setInputFiles(join(import.meta.dirname, 'fixtures', 'similar-b.jpg'));
	const picture = card.locator('.prof-av img');
	await expect(picture).toBeVisible();
	await expect
		.poll(() => picture.evaluate((image: HTMLImageElement) => image.naturalWidth))
		.toBeGreaterThan(0);
	// The account button in the header shows it too.
	await expect(page.locator('.av.pic img')).toBeVisible();

	await card.getByRole('button', { name: 'Remove' }).click();
	await expect(picture).toHaveCount(0);
	await expect(card.locator('.prof-av')).toHaveText('EP');

	await card.getByLabel('Email address').fill('e2e-importer-new@example.com');
	await expect(card.getByLabel(/Current password/)).toBeVisible();
});
