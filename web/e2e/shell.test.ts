import { expect, test, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { photo, signIn, users, settledTiles } from './helpers';

test.beforeEach(async ({ page }) => {
	await page.addInitScript(() => {
		if (!localStorage.getItem('mediarr_lang')) localStorage.setItem('mediarr_lang', 'hr');
	});
});

test('the interface defaults to English', async ({ page }) => {
	await signIn(page, 'admin');
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', ''));
	// A new account has no language yet; other tests save one to this account.
	await page.route('**/api/auth/status', async (route) => {
		const response = await route.fetch();
		const status = await response.json();
		delete status.user?.language;
		await route.fulfill({ response, json: status });
	});
	await page.goto('/');
	await expect(page.getByRole('heading', { name: 'Media' })).toBeVisible();
	await expect(page.locator('html')).toHaveAttribute('lang', 'en');
});

test('the logo is the fan of six photos and the name, on the web and in the tab', async ({
	page,
	request
}) => {
	await signIn(page, 'admin');
	await page.goto('/');
	const logo = page.getByRole('link', { name: 'Mediarr' }).first();
	await expect(logo).toBeVisible();
	await expect(logo.locator('.brand-mark rect')).toHaveCount(6);
	await expect(logo.locator('.brand-word')).toHaveText('medıarr');
	const icon = await request.get('/favicon.svg');
	expect(icon.ok()).toBe(true);
	expect((await icon.text()).match(/<rect /g)).toHaveLength(6);
	expect((await request.get('/brand/logo.svg')).ok()).toBe(true);
});

test('the dock and More hold the planned sections and navigate', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/');
	const nav = page.getByRole('navigation', { name: 'Navigacija' });
	await nav.getByRole('button', { name: 'Više' }).click();
	for (const label of [
		'Mediji',
		'Pretraga',
		'Karta',
		'Ljudi',
		'Albumi',
		'Dijeljeno',
		'Obitelj',
		'Memories',
		'Mape',
		'Dokumenti',
		'Duplikati',
		'Arhiva',
		'Smeće',
		'Trezor'
	]) {
		await expect(nav.getByRole('link', { name: label })).toBeVisible();
	}
	await nav.getByRole('link', { name: 'Albumi' }).click();
	await expect(page).toHaveURL(/\/albums$/);
	// Choosing a place closes More.
	await expect(nav.getByRole('link', { name: 'Smeće' })).toHaveCount(0);
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
	await page.getByRole('button', { name: 'Račun' }).click();
	await page.getByRole('radio', { name: 'Svijetlo' }).click();
	await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
	await expect(page.getByRole('radio', { name: 'Svijetlo' })).toHaveAttribute(
		'aria-checked',
		'true'
	);
	await page.reload();
	await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('language menu switches the interface', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/');
	await page.getByRole('button', { name: 'Račun' }).click();
	await page.getByLabel('Jezik').selectOption('en');
	await expect(page.getByRole('link', { name: 'Media', exact: true })).toBeVisible();
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

test('on a phone, More opens and closes', async ({ page }) => {
	await signIn(page, 'admin');
	await page.setViewportSize({ width: 390, height: 800 });
	await page.goto('/');
	const more = page.getByRole('button', { name: 'Više' });
	await more.click();
	await expect(more).toHaveAttribute('aria-expanded', 'true');
	await expect(page.getByRole('link', { name: 'Smeće' })).toBeVisible();
	await page.keyboard.press('Escape');
	await expect(more).toHaveAttribute('aria-expanded', 'false');
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
	test.skip(!process.env.E2E_PROD_URL, 'needs E2E_PROD_URL, the address of a production image');
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
	await expect(page.getByRole('heading', { name: 'Mediji' })).toBeVisible();
	expect(new URL(page.url()).host).not.toBe('example.com');
});

test('More shows the disk, the server and its version', async ({ page }) => {
	await signIn(page, 'user');
	await page.goto('/');
	await page.getByRole('button', { name: 'Više' }).click();
	await expect(page.locator('.srv-card')).toBeVisible();
	await expect(page.locator('.srv-line')).toContainText(/\S/);
	await expect(page.locator('.srv-dot.off')).toHaveCount(0);
});

test('security refuses a list that would lock out the person setting it', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	await page.goto('/admin/security');
	await expect(page.getByText('The server sees you at')).toBeVisible();
	await page.getByLabel('Allow only these addresses and networks').check();
	await page.getByLabel('One a line').fill('203.0.113.9');
	await page.getByRole('button', { name: 'Save' }).click();
	await expect(page.getByText('lock you out')).toBeVisible();
	await expect(page.getByRole('heading', { name: /Attempts to connect/ })).toBeVisible();
});

test('the account page shows the library and this device', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'user');
	await page.goto('/account');
	await expect(page.getByRole('heading', { name: 'Your library' })).toBeVisible();
	await expect(page.locator('.acct-stats')).toBeVisible();
	await expect(page.getByText('This device')).toBeVisible();
});

test('a section can be taken off the menu and put back', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'user');
	await page.goto('/account');
	const side = page.getByRole('navigation', { name: 'Navigation' });
	await expect(side.getByRole('link', { name: 'Map' })).toBeVisible();
	const toggle = page.locator('main').getByLabel('Map', { exact: true });
	await toggle.uncheck();
	await expect(side.getByRole('link', { name: 'Map' })).toHaveCount(0);
	await toggle.check();
	await expect(side.getByRole('link', { name: 'Map' })).toBeVisible();
});

test('a message from the administrator shows on the sign-in page', async ({ browser, page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	await page.goto('/admin/settings');
	const field = page.getByLabel('Message on the sign-in page');
	await field.fill('Welcome to this server');
	const hours = page.getByLabel('Scan the external library every this many hours');
	const hoursBefore = await hours.inputValue();
	await hours.fill('12');
	await field.locator('xpath=ancestor::form').getByRole('button', { name: 'Save' }).click();
	await expect(page.getByText('Saved.')).toBeVisible();
	await page.reload();
	await expect(hours).toHaveValue('12');
	await hours.fill(hoursBefore);

	const stranger = await browser.newPage();
	await stranger.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await stranger.goto('/login');
	await expect(stranger.getByText('Welcome to this server')).toBeVisible();
	await stranger.close();

	await field.fill('');
	await field.locator('xpath=ancestor::form').getByRole('button', { name: 'Save' }).click();
	await expect(page.getByText('Saved.').last()).toBeVisible();
});

test('an administrator can check the originals and read the report', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	await page.goto('/admin/health');
	await page.getByRole('button', { name: 'Check now' }).click();
	await expect(page.getByRole('status').filter({ hasText: 'Started.' })).toBeVisible();
	await expect(async () => {
		await page.reload();
		await expect(page.getByText('Last check')).toBeVisible({ timeout: 2000 });
	}).toPass({ timeout: 90_000 });
});

test('the bell shows notifications and says when there are none', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'user');
	await page.goto('/');
	await page.getByRole('button', { name: 'Notifications' }).click();
	await expect(
		page
			.locator('.notify-panel')
			.getByText(/No notifications|shared with you|import|backup/i)
			.first()
	).toBeVisible();
});

test('email can be set up, and says what a link needs', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	await page.goto('/admin/settings');
	await expect(page.getByRole('heading', { name: 'Email' })).toBeVisible();
	await expect(page.getByLabel('Address of this server')).toBeVisible();
	await expect(page.getByText('no link for a new password is sent')).toBeVisible();
});

test('a link that is not valid says so', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await page.goto('/login/reset?token=not-a-real-token');
	await page.getByLabel('New password').fill('a-completely-new-password');
	await page.getByRole('button', { name: 'Save' }).click();
	await expect(page.getByRole('alert')).toContainText('expired');
});

test('signing out ends the session', async ({ page }) => {
	await signIn(page, 'user');
	await page.goto('/');
	await page.getByRole('button', { name: 'Račun' }).click();
	await page.getByRole('button', { name: 'Odjava' }).click();
	await expect(page).toHaveURL(/\/login$/);
	await page.goto('/');
	await expect(page).toHaveURL(/\/login/);
});

test('administration is closed to normal users', async ({ page }) => {
	await signIn(page, 'user');
	await page.goto('/admin');
	await expect(page.getByRole('heading', { name: 'Mediji' })).toBeVisible();
	await expect(page.getByRole('link', { name: 'Administracija' })).toHaveCount(0);
});

test('an administrator can see the users', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/admin/users');
	await expect(page.getByRole('cell', { name: users.user })).toBeVisible();
});

// A small real JPEG, made unique so that every run starts as a new file.
async function uploadPhoto(page: Page, name: string) {
	const file = photo(name);
	await page.locator('input[type=file]').last().setInputFiles(file);
	return file;
}

test.describe('timeline', () => {
	test.describe.configure({ mode: 'serial' });

	test('an uploaded photo appears on the timeline, and a copy is deduplicated', async ({
		page
	}) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('main').waitFor();
		const before = await settledTiles(page);
		const file = await uploadPhoto(page, `e2e-${Date.now()}.jpg`);
		await expect(page.locator('.tl-tile')).toHaveCount(before + 1, { timeout: 45000 });
		const image = page.locator('.tl-tile img').first();
		await expect(image).toHaveJSProperty('complete', true);
		expect(await image.evaluate((img: HTMLImageElement) => img.naturalWidth)).toBeGreaterThan(0);

		await page
			.locator('input[type=file]')
			.last()
			.setInputFiles({ ...file, name: `copy-${file.name}` });
		await expect(page.getByText('već postoji: 1')).toBeVisible({ timeout: 30000 });
	});

	test('the viewer opens, shows details, closes and keeps the scroll position', async ({
		page
	}) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('.tl-tile').first().click();
		await expect(page).toHaveURL(/\/photos\//);
		const viewer = page.getByRole('dialog');
		await expect(viewer.locator('img.viewer-media:not(.under)').first()).toBeVisible();
		await viewer.getByRole('button', { name: 'Podaci' }).click();
		await expect(viewer.locator('.kv', { hasText: 'Veličina' })).toBeVisible();
		await page.keyboard.press('Escape');
		await expect(viewer.locator('.viewer-info')).toHaveCount(0);
		await page.keyboard.press('Escape');
		await expect(page).toHaveURL(/127\.0\.0\.1:\d+\/$/);
		await expect(viewer).toHaveCount(0);
	});

	test('the arrow keys move between photos, and a viewer link works directly', async ({ page }) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('main').waitFor();
		await uploadPhoto(page, `e2e-second-${Date.now()}.jpg`);
		await expect(page.locator('.tl-tile').nth(1)).toBeVisible({ timeout: 45000 });
		await page.locator('.tl-tile').first().click();
		await expect(page).toHaveURL(/\/photos\//);
		const first = page.url();
		// The strip shows the photos around this one, and opens them.
		const strip = page.getByRole('navigation', { name: 'Susjedne fotke' });
		await expect(strip.getByRole('button', { name: 'Otvori fotku' }).first()).toBeVisible();
		await expect(strip.locator('[aria-current="true"]')).toHaveCount(1);
		await expect(
			page.getByRole('dialog').locator('img.viewer-media:not(.under)').first()
		).toBeVisible();
		await page.keyboard.press('ArrowRight');
		await expect(page).not.toHaveURL(first);
		const second = page.url();
		await page.goto(second);
		await expect(
			page.getByRole('dialog').locator('img.viewer-media:not(.under)').first()
		).toBeVisible();
		// The keys work once the viewer knows its neighbours, which it reads after the picture appears.
		await expect(async () => {
			await page.keyboard.press('ArrowLeft');
			await expect(page).toHaveURL(first, { timeout: 1000 });
		}).toPass({ timeout: 15_000 });
	});

	test('favorite and delete work from the selection toolbar', async ({ page }) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		const tile = page.locator('.tl-tile').first();
		await tile.hover();
		await tile.locator('.tl-check').click();
		const bar = page.getByRole('toolbar');
		await expect(bar.locator('.selbar-n')).toHaveText('1');
		await bar.getByRole('button', { name: 'Dodaj u favorite' }).click();
		await expect(page.locator('.tl-fav').first()).toBeVisible();

		const before = await settledTiles(page);
		await tile.hover();
		await tile.locator('.tl-check').click();
		await bar.getByRole('button', { name: 'Obriši' }).click();
		await page.getByRole('dialog').getByRole('button', { name: 'Obriši' }).click();
		await expect(page.locator('.tl-tile')).toHaveCount(before - 1);
	});

	test('several files chosen in the picker all upload, even in a row', async ({ page }) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('main').waitFor();
		const before = await settledTiles(page);
		for (const batch of [
			[1, 2, 3, 4, 5],
			[6, 7]
		]) {
			const [chooser] = await Promise.all([
				page.waitForEvent('filechooser'),
				page.getByRole('button', { name: 'Dodaj' }).click()
			]);
			expect(chooser.isMultiple()).toBe(true);
			await chooser.setFiles(batch.map((n) => photo(`image-${n}.jpg`)));
		}
		await expect(page.locator('.tl-tile').nth(before + 6)).toBeAttached({ timeout: 60000 });
		// A sent file leaves the list by itself; only one that failed would stay.
		await expect(page.locator('.kv', { hasText: 'image-' })).toHaveCount(0, { timeout: 15000 });
	});

	test('a video is transcoded and its stream is served to the owner', async ({ page }) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('main').waitFor();
		const clip = readFileSync(join(import.meta.dirname, 'fixtures', 'clip.mp4'));
		const name = `clip-${Date.now()}.mp4`;
		// Trailing bytes make it a new file every run. Players ignore them.
		await page
			.locator('input[type=file]')
			.last()
			.setInputFiles({
				name,
				mimeType: 'video/mp4',
				buffer: Buffer.concat([clip, Buffer.from(String(Math.random()))])
			});
		await expect(page.locator('.tl-video').first()).toBeVisible({ timeout: 45000 });

		await page.locator('.tl-video').first().locator('..').click();
		await expect(page.locator('video.viewer-media')).toBeAttached();
		const id = page.url().split('/').pop();

		await expect
			.poll(
				async () => (await (await page.request.get(`/api/assets/${id}`)).json()).hlsReady === true,
				{ timeout: 90000 }
			)
			.toBe(true);

		const master = await page.request.get(`/api/assets/${id}/video/master.m3u8`);
		expect(master.status()).toBe(200);
		expect(await master.text()).toContain('.m3u8');
		const sprite = await page.request.get(`/api/assets/${id}/video/sprite.jpg`);
		expect(sprite.status()).toBe(200);

		// Reproduction needs a browser with H.264. Test Chromium has none; Safari and Chrome do.
		await page.reload();
		const video = page.locator('video.viewer-media');
		await video.waitFor({ state: 'attached' });
		const canPlay = await video.evaluate(
			(element: HTMLVideoElement) => element.canPlayType('video/mp4; codecs="avc1.42E01E"') !== ''
		);
		if (canPlay) {
			await expect
				.poll(() => video.evaluate((element: HTMLVideoElement) => element.readyState), {
					timeout: 20000
				})
				.toBeGreaterThan(0);
		}
	});

	test('zooming a photo asks for the full resolution', async ({ page }) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('main').waitFor();
		await uploadPhoto(page, `e2e-zoom-${Date.now()}.jpg`);
		const tile = page.locator('.tl-tile:not(:has(.tl-video))').first();
		await tile.waitFor({ timeout: 45000 });
		// By default the full resolution comes as the viewer opens; zooming asks for it otherwise.
		const full = page.waitForResponse((response) => response.url().includes('size=full'));
		await tile.click();
		await page.locator('img.viewer-media:not(.under)').first().waitFor();
		await page.locator('.viewer-stage').hover();
		await page.mouse.wheel(0, -400);
		expect((await full).status()).toBe(200);
	});

	test('a damaged file is reported with an error', async ({ page }) => {
		await signIn(page, 'uploader');
		await page.goto('/');
		await page.locator('main').waitFor();
		const name = `broken-${Date.now()}.jpg`;
		await page
			.locator('input[type=file]')
			.last()
			.setInputFiles({
				name,
				mimeType: 'image/jpeg',
				buffer: Buffer.from(`not an image ${Date.now()}`)
			});
		// The page stays put while it uploads; then the failure is reported in the account, not over
		// the photos.
		await expect
			.poll(
				async () =>
					(await (await page.request.get('/api/assets?limit=200&status=failed')).json()).items
						.map((asset: { originalName: string }) => asset.originalName)
						.includes(name),
				{ timeout: 60_000 }
			)
			.toBe(true);
		await page.goto('/account');
		await expect(page.getByText('datoteka se nije moglo obraditi')).toBeVisible();
		await page.getByRole('button', { name: 'Prikaži', exact: true }).click();
		await expect(page.getByRole('cell', { name })).toBeVisible();
	});

	test('a long press selects a photo on a touch screen', async ({ browser }) => {
		const context = await browser.newContext({
			baseURL: 'http://127.0.0.1:9852',
			hasTouch: true,
			isMobile: true,
			viewport: { width: 390, height: 800 }
		});
		const page = await context.newPage();
		await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'hr'));
		await signIn(page, 'uploader');
		await page.goto('/');
		const tile = page.locator('.tl-tile').first();
		await tile.waitFor();
		const box = await tile.boundingBox();
		const client = await context.newCDPSession(page);
		const point = { x: box!.x + box!.width / 2, y: box!.y + box!.height / 2 };
		await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [point] });
		// Well past the 450 ms of a long press: under load the page's timer can fire late.
		await page.waitForTimeout(1200);
		await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
		await expect(page.getByRole('toolbar').locator('.selbar-n')).toHaveText('1');
		await expect(page).not.toHaveURL(/\/photos\//);
		const overflow = await page.evaluate(
			() => document.documentElement.scrollWidth - document.documentElement.clientWidth
		);
		expect(overflow).toBeLessThanOrEqual(0);
		await context.close();
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

test('jobs can be paused, and storage shows each user', async ({ page }) => {
	await signIn(page, 'admin');
	await page.goto('/admin/jobs');
	const video = page.locator('[data-queue="video"]');
	await expect(video).toContainText(/Radi|Running/);
	await video.getByRole('button', { name: /Pauziraj|Pause/ }).click();
	await expect(video).toContainText(/Pauzirano|Paused/);
	await video.getByRole('button', { name: /Nastavi|Resume/ }).click();
	await expect(video).toContainText(/Radi|Running/);

	await page.goto('/admin/storage');
	const row = page.locator('[data-user="e2e-user@example.com"]');
	await row.getByRole('textbox').fill('5');
	// The page is read again only once the server has the new quota.
	const saved = page.waitForResponse(
		(response) => response.url().includes('/quota') && response.request().method() !== 'GET'
	);
	await row.getByRole('button', { name: /Spremi|Save/ }).click();
	expect((await saved).ok()).toBe(true);
	await page.reload();
	await expect(row.getByRole('textbox')).toHaveValue('5');
	await row.getByRole('textbox').fill('');
	await row.getByRole('button', { name: /Spremi|Save/ }).click();

	await page.goto('/admin/health');
	await expect(page.getByText(/Pozadinski poslovi rade|Background jobs are running/)).toBeVisible();
});

test('a backup is set up, runs, and its test of coming back passes', async ({ page }) => {
	test.setTimeout(180000);
	await signIn(page, 'admin');
	await page.goto('/admin/settings');
	const secret = 'e2e-backup-password';
	await page.getByLabel(/Odredište|Destination/).fill(`/backup/e2e-${Date.now()}`);
	await page
		.getByLabel(/Lozinka backupa|Backup password|Lozinka \(spremljena|Password \(saved/)
		.fill(secret);
	await page.getByTestId('backup-save').click();
	await expect(page.getByLabel(/Lozinka \(spremljena|Password \(saved/)).toBeVisible();
	expect(await page.content()).not.toContain(secret);

	await page.getByRole('button', { name: /Backup sada|Back up now/ }).click();
	const backup = page.locator('[data-backup-run="backup"]').first();
	await expect(backup).toContainText(/Gotovo|Done/i, { timeout: 90000 });
	await page.getByRole('button', { name: /Testiraj vraćanje|Test bringing it back/ }).click();
	const test_ = page.locator('[data-backup-run="restore_test"]').first();
	await expect(test_).toContainText(/Gotovo|Done/i, { timeout: 90000 });

	await page.locator('[data-feature="kiosk"]').check();
	await page.reload();
	await expect(page.locator('[data-feature="kiosk"]')).toBeChecked();
	await page.locator('[data-feature="kiosk"]').uncheck();

	// The test leaves the demo as it found it.
	await page.request.put('/api/admin/backup', { data: { repository: '', hour: 3 } });
});

test('a settings page lists its parts and jumps to one', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'user');
	await page.goto('/account');
	const parts = page.getByRole('navigation', { name: 'Sections' });
	await parts.getByRole('link', { name: 'API keys' }).click();
	await expect(page.getByRole('heading', { name: 'API keys' })).toBeInViewport();
	await expect(parts.getByRole('link', { name: 'API keys' })).toHaveAttribute(
		'aria-current',
		'location'
	);
});

test('the admin sees how the analysis service is doing', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	const health = {
		workerRunning: true,
		mlEnabled: true,
		databaseBytes: 1000
	};
	await page.route('**/api/admin/health', (route) =>
		route.fulfill({
			json: {
				...health,
				mlRunning: true,
				ml: {
					state: 'connected',
					models: [
						{ name: 'clip-text', loaded: true, inUse: 0, idleSeconds: 2 },
						{ name: 'ocr', loaded: false, inUse: 0 }
					],
					rssBytes: 104857600,
					acceleration: { requested: 'cpu', providers: ['CPUExecutionProvider'] },
					idleMinutes: 5
				}
			}
		})
	);
	await page.goto('/admin/health');
	await expect(page.getByTestId('ml-state')).toContainText('Connected');
	await expect(page.locator('.kv', { hasText: 'Loaded models' })).toContainText('clip-text');
	await expect(page.locator('.kv', { hasText: 'Acceleration' })).toContainText('cpu');
	await page.unroute('**/api/admin/health');

	await page.route('**/api/admin/health', (route) =>
		route.fulfill({ json: { ...health, mlRunning: false, ml: { state: 'wrongToken' } } })
	);
	await page.reload();
	await expect(page.getByTestId('ml-state')).toContainText('refused the token');
});

test('a search without the analysis service says so', async ({ page }) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	await page.route('**/api/search?*', (route) =>
		route.fulfill({ json: { items: [], smart: false, filters: { words: 'beach' } } })
	);
	await page.goto('/search?q=beach');
	await expect(page.getByRole('status').filter({ hasText: 'Smart search is off' })).toBeVisible();
});
