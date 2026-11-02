import { expect, test } from '@playwright/test';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'hr'));
});

test('the interface defaults to English', async ({ page }) => {
	await page.addInitScript(() => localStorage.removeItem('mediarr_lang'));
	await page.goto('/');
	await expect(page.getByRole('heading', { name: 'Photos' })).toBeVisible();
	await expect(page.locator('html')).toHaveAttribute('lang', 'en');
});

test('app sidebar has the planned sections and navigates', async ({ page }) => {
	await page.goto('/');
	const nav = page.getByRole('navigation').first();
	for (const label of [
		'Fotke',
		'Pretraga',
		'Karta',
		'Ljudi',
		'Albumi',
		'Dijeljeno',
		'Memories',
		'Arhiva',
		'Smeće',
		'Trezor'
	]) {
		await expect(nav.getByRole('link', { name: label })).toBeVisible();
	}
	await nav.getByRole('link', { name: 'Albumi' }).click();
	await expect(page).toHaveURL(/\/albums$/);
	await expect(page.getByRole('heading', { name: 'Albumi' })).toBeVisible();
	await expect(nav.getByRole('link', { name: 'Albumi' })).toHaveAttribute('aria-current', 'page');
});

test('unknown section is a 404', async ({ page }) => {
	await page.goto('/nope');
	await expect(page.getByRole('heading', { name: '404' })).toBeVisible();
});

test('admin has its tag, the app does not', async ({ page }) => {
	await page.goto('/admin');
	await expect(page.locator('.logo-tag')).toHaveText('ADMIN');
	await page.goto('/');
	await expect(page.locator('.logo-tag')).toHaveCount(0);
});

test('theme toggle persists across reloads', async ({ page }) => {
	await page.addInitScript(() => {
		if (!sessionStorage.getItem('seeded')) {
			sessionStorage.setItem('seeded', '1');
			localStorage.setItem('mediarr_theme', 'dark');
		}
	});
	await page.goto('/');
	await page.getByRole('button', { name: 'Promijeni temu' }).click();
	await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
	await page.reload();
	await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('language menu switches the interface', async ({ page }) => {
	await page.goto('/');
	await page.locator('.langdd summary').click();
	await page.getByRole('menuitem', { name: /English/ }).click();
	await expect(page.getByRole('link', { name: 'Photos', exact: true })).toBeVisible();
	await expect(page.locator('html')).toHaveAttribute('lang', 'en');
});

test('command palette opens with Ctrl+K and navigates', async ({ page }) => {
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.keyboard.press('Control+k');
	const input = page.getByRole('searchbox', { name: 'Traži naredbu' });
	await expect(input).toBeVisible();
	await input.fill('kart');
	await page.keyboard.press('Enter');
	await expect(page).toHaveURL(/\/map$/);
});

test('mobile menu opens and closes', async ({ page }) => {
	await page.setViewportSize({ width: 390, height: 800 });
	await page.goto('/');
	await page.getByRole('button', { name: 'Otvori izbornik' }).click();
	await expect(page.locator('html')).toHaveClass(/side-open/);
	await page.keyboard.press('Escape');
	await expect(page.locator('html')).not.toHaveClass(/side-open/);
});

test('dialog, sheet and toast work', async ({ page }) => {
	await page.goto('/dev/components');
	await page.getByRole('button', { name: 'Dialog', exact: true }).click();
	await expect(page.getByRole('dialog', { name: 'Primjer dijaloga' })).toBeVisible();
	await page.getByRole('button', { name: 'U redu' }).click();
	await expect(page.getByRole('dialog', { name: 'Primjer dijaloga' })).toBeHidden();

	await page.getByRole('button', { name: 'Sheet', exact: true }).click();
	await expect(page.getByRole('dialog', { name: 'Primjer panela' })).toBeVisible();
	await page.keyboard.press('Escape');
	await expect(page.getByRole('dialog', { name: 'Primjer panela' })).toBeHidden();

	await page.getByRole('button', { name: 'Toast', exact: true }).click();
	await expect(page.getByText('Spremljeno')).toBeVisible();
});

test('login password can be revealed', async ({ page }) => {
	await page.goto('/login');
	const password = page.getByLabel('Lozinka', { exact: true });
	await expect(password).toHaveAttribute('type', 'password');
	await page.getByRole('button', { name: 'Prikaži lozinku' }).click();
	await expect(password).toHaveAttribute('type', 'text');
});

test('single photo view has a clean background', async ({ page }) => {
	await page.goto('/dev/plain');
	await expect(page.locator('.sky')).toBeHidden();
});

test('production hides the development pages', async ({ page }) => {
	test.skip(!process.env.E2E_PROD_URL, 'needs E2E_PROD_URL');
	await page.goto(`${process.env.E2E_PROD_URL}/dev/components`);
	await expect(page.getByRole('heading', { name: '404' })).toBeVisible();
});
