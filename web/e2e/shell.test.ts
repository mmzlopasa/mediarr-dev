import { expect, test } from '@playwright/test';
import { signIn, users } from './helpers';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => {
		if (!localStorage.getItem('mediarr_lang')) localStorage.setItem('mediarr_lang', 'hr');
	});
});

test('the interface defaults to English', async ({ page }) => {
	await signIn(page, 'admin');
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', ''));
	await page.goto('/');
	await expect(page.getByRole('heading', { name: 'Photos' })).toBeVisible();
	await expect(page.locator('html')).toHaveAttribute('lang', 'en');
});

test('app sidebar has the planned sections and navigates', async ({ page }) => {
	await signIn(page, 'admin');
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
	await signIn(page, 'admin');
	await page.goto('/nope');
	await expect(page.getByRole('heading', { name: '404' })).toBeVisible();
});

test('admin has its tag, the app does not', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/admin');
	await expect(page.locator('.logo-tag')).toHaveText('ADMIN');
	await page.goto('/');
	await expect(page.locator('.logo-tag')).toHaveCount(0);
});

test('theme toggle persists across reloads', async ({ page }) => {
	await signIn(page, 'admin');
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
	await signIn(page, 'admin');
	await page.goto('/');
	await page.locator('.langdd summary').click();
	await page.getByRole('menuitem', { name: /English/ }).click();
	await expect(page.getByRole('link', { name: 'Photos', exact: true })).toBeVisible();
	await expect(page.locator('html')).toHaveAttribute('lang', 'en');
});

test('command palette opens with Ctrl+K and navigates', async ({ page }) => {
	await signIn(page, 'admin');
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
	await signIn(page, 'admin');
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

test('pages require signing in and return afterwards', async ({ page }) => {
	await page.goto('/albums');
	await expect(page).toHaveURL(/\/login\?next=%2Falbums$/);
	await page.getByLabel('E-adresa').fill(users.user);
	await page.getByLabel('Lozinka', { exact: true }).fill(process.env.E2E_PASSWORD!);
	await page.getByRole('button', { name: 'Prijavi se' }).click();
	await expect(page).toHaveURL(/\/albums$/);
});

test('a wrong password shows an error', async ({ page }) => {
	await page.goto('/login');
	await page.getByLabel('E-adresa').fill('nobody@example.com');
	await page.getByLabel('Lozinka', { exact: true }).fill('not the right password');
	await page.getByRole('button', { name: 'Prijavi se' }).click();
	await expect(page.getByRole('alert')).toContainText('Pogrešna');
});

test('a sign-in link cannot redirect to another site', async ({ page }) => {
	await page.goto('/login?next=//example.com');
	await page.getByLabel('E-adresa').fill(users.user);
	await page.getByLabel('Lozinka', { exact: true }).fill(process.env.E2E_PASSWORD!);
	await page.getByRole('button', { name: 'Prijavi se' }).click();
	await expect(page.getByRole('heading', { name: 'Fotke' })).toBeVisible();
	expect(new URL(page.url()).host).not.toBe('example.com');
});

test('signing out ends the session', async ({ page }) => {
	await signIn(page, 'user');
	await page.goto('/');
	await page.getByRole('button', { name: 'Odjava' }).click();
	await expect(page).toHaveURL(/\/login$/);
	await page.goto('/');
	await expect(page).toHaveURL(/\/login/);
});

test('administration is closed to normal users', async ({ page }) => {
	await signIn(page, 'user');
	await page.goto('/admin');
	await expect(page.getByRole('heading', { name: 'Fotke' })).toBeVisible();
	await expect(page.getByRole('link', { name: 'Administracija' })).toHaveCount(0);
});

test('an administrator can see the users', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/admin/users');
	await expect(page.getByRole('cell', { name: users.user })).toBeVisible();
});

test('uploading shows progress, finishes processing and deduplicates', async ({ page }) => {
	await signIn(page, 'uploader');
	await page.goto('/');
	await page.locator('main').waitFor();

	// A tiny valid PNG, made unique so that every run starts as a new file.
	const png = Buffer.from(
		'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEBgIApD5fRAAAAABJRU5ErkJggg==',
		'base64'
	);
	const unique = Buffer.concat([png, Buffer.from(String(Date.now()))]);
	const name = `e2e-${Date.now()}.png`;
	const input = page.locator('input[type=file]');

	await input.setInputFiles({ name, mimeType: 'image/png', buffer: unique });
	const row = page.getByRole('row', { name: new RegExp(name) });
	await expect(row.getByText('Spremno')).toBeVisible({ timeout: 30000 });

	await input.setInputFiles({ name: `copy-${name}`, mimeType: 'image/png', buffer: unique });
	await expect(page.getByText('Već postoji')).toBeVisible({ timeout: 30000 });
});

test('a damaged file shows an error instead of hanging', async ({ page }) => {
	await signIn(page, 'uploader');
	await page.goto('/');
	await page.locator('main').waitFor();
	const name = `broken-${Date.now()}.jpg`;
	await page.locator('input[type=file]').setInputFiles({
		name,
		mimeType: 'image/jpeg',
		buffer: Buffer.from(`not an image ${Date.now()}`)
	});
	await expect(page.getByRole('row', { name: new RegExp(name) }).getByText('Greška')).toBeVisible({
		timeout: 30000
	});
});

test('the admin overview shows live numbers from the server', async ({ page }) => {
	await signIn(page, 'admin');
	const response = await page.request.get('/api/admin/overview');
	const overview = await response.json();
	expect(overview.users).toBeGreaterThan(0);
	expect(overview.diskTotalBytes).toBeGreaterThan(0);

	await page.goto('/admin');
	const users = page.locator('.stat', { hasText: 'Korisnici' }).locator('.stat-v');
	await expect(users).toHaveText(String(overview.users));
	await expect(page.locator('.kv', { hasText: 'Baza' })).toContainText(overview.databaseVersion);

	for (const [path, text] of [
		['/admin/jobs', 'Dovršeno'],
		['/admin/storage', 'Slobodno na disku'],
		['/admin/health', 'Baza']
	]) {
		await page.goto(path);
		await expect(page.locator('.kv', { hasText: text }).first()).toBeVisible();
	}
});

test('input text is large enough that iOS does not zoom on focus', async ({ page }) => {
	await signIn(page, 'admin');
	await page.setViewportSize({ width: 390, height: 800 });
	await page.goto('/account');
	await page.locator('main .in').first().waitFor();
	const sizes = await page
		.locator('main input.in')
		.evaluateAll((inputs) => inputs.map((input) => parseFloat(getComputedStyle(input).fontSize)));
	expect(Math.min(...sizes)).toBeGreaterThanOrEqual(16);
});

test('no page scrolls sideways on a phone', async ({ page }) => {
	await signIn(page, 'admin');
	await page.setViewportSize({ width: 320, height: 700 });
	for (const path of [
		'/',
		'/albums',
		'/account',
		'/admin',
		'/admin/users',
		'/admin/jobs',
		'/admin/storage',
		'/admin/health'
	]) {
		await page.goto(path);
		await page.locator('main').first().waitFor();
		const overflow = await page.evaluate(
			() => document.documentElement.scrollWidth - document.documentElement.clientWidth
		);
		expect(overflow, path).toBeLessThanOrEqual(0);
	}
});
