import { expect, test, type Page } from '@playwright/test';
import { photo, signIn } from './helpers';

async function upload(page: Page, prefix: string) {
	const name = `${prefix}-${Date.now()}.jpg`;
	await page.goto('/');
	await page.locator('main').waitFor();
	await page.locator('input[type=file]').last().setInputFiles(photo(name));
	let id = '';
	await expect
		.poll(
			async () => {
				const list = await (await page.request.get('/api/assets?limit=50')).json();
				id =
					list.items.find(
						(asset: { originalName: string; status: string }) =>
							asset.originalName === name && asset.status === 'ready'
					)?.id ?? '';
				return id;
			},
			{ timeout: 60_000 }
		)
		.not.toBe('');
	return id;
}

// Chrome treats 127.0.0.1 as secure, so plain HTTP on the address of a server is stood in for.
test('on plain HTTP the web does not offer Cast, and says why', async ({ page }) => {
	await page.addInitScript(() => {
		localStorage.setItem('mediarr_lang', 'en');
		Object.defineProperty(window, 'isSecureContext', { get: () => false, configurable: true });
		(window as unknown as { chrome?: object }).chrome ??= {};
	});
	await signIn(page, 'importer');
	const id = await upload(page, 'cast-http');
	await page.goto(`/photos/${id}`);
	await page.getByRole('button', { name: 'Play on TV' }).click();
	const menu = page.getByRole('menu', { name: 'Play on TV' });
	const chromecast = menu.getByRole('menuitem', { name: /Chromecast/ });
	await expect(chromecast).toHaveAttribute('aria-disabled', 'true');
	await expect(chromecast).toContainText('Chrome allows Cast only on HTTPS');
	await expect(chromecast).toContainText('Use the Mediarr app');
	await expect(menu.getByRole('menuitem', { name: /DLNA/ })).toContainText(
		'A browser cannot reach DLNA TVs'
	);
	await expect(menu.getByRole('menuitem', { name: /AirPlay/ })).toHaveAttribute(
		'aria-disabled',
		'true'
	);
	// Nothing is started by it.
	await chromecast.click({ force: true });
	await expect(page.getByRole('region', { name: /Playing on/ })).toHaveCount(0);
});

// Google's Cast sender cannot reach a real TV here, so a stand-in records what the TV is told to load.
test('a Chromecast shows the photo, follows the slideshow, and loses the token when stopped', async ({
	page,
	playwright
}) => {
	await page.addInitScript(() => {
		localStorage.setItem('mediarr_lang', 'en');
		const loaded: string[] = [];
		let current: object | null = null;
		const w = window as unknown as Record<string, unknown> & { chrome?: Record<string, unknown> };
		w.loadedOnTv = loaded;
		const session = {
			loadMedia: async (request: { media: { contentId: string } }) => {
				loaded.push(request.media.contentId);
			},
			getCastDevice: () => ({ friendlyName: 'Living room' })
		};
		const context = {
			setOptions: () => undefined,
			requestSession: async () => {
				current = session;
			},
			getCurrentSession: () => current,
			endCurrentSession: () => {
				current = null;
				w.endedOnTv = true;
			},
			addEventListener: () => undefined
		};
		w.chrome = w.chrome ?? {};
		w.chrome.cast = {
			AutoJoinPolicy: { ORIGIN_SCOPED: 'origin_scoped' },
			media: {
				DEFAULT_MEDIA_RECEIVER_APP_ID: 'CC1AD845',
				MediaInfo: class {
					constructor(
						public contentId: string,
						public contentType: string
					) {}
				},
				PhotoMediaMetadata: class {},
				GenericMediaMetadata: class {},
				LoadRequest: class {
					constructor(public media: unknown) {}
				}
			}
		};
		w.cast = {
			framework: {
				CastContext: { getInstance: () => context },
				RemotePlayer: class {
					isPaused = false;
					currentTime = 0;
					duration = 0;
				},
				RemotePlayerController: class {
					playOrPause() {}
					seek() {}
					addEventListener() {}
				},
				RemotePlayerEventType: { ANY_CHANGE: 'anyChanged' },
				CastContextEventType: { SESSION_STATE_CHANGED: 'sessionstatechanged' },
				SessionState: { SESSION_ENDED: 'SESSION_ENDED' }
			}
		};
	});
	test.setTimeout(90_000);
	await signIn(page, 'importer');
	const second = await upload(page, 'cast-second');
	const first = await upload(page, 'cast-first');
	const loaded = () =>
		page.evaluate(() => (window as unknown as { loadedOnTv: string[] }).loadedOnTv.slice());
	const tv = await playwright.request.newContext();

	// From the viewer.
	await page.goto(`/photos/${first}`);
	await page.getByRole('button', { name: 'Play on TV' }).click();
	await page.getByRole('menuitem', { name: /Chromecast/ }).click();
	await expect(page.getByRole('region', { name: 'Playing on Living room' })).toBeVisible();
	await expect.poll(async () => (await loaded()).length).toBe(1);
	const [shown] = await loaded();
	expect(shown).toMatch(new RegExp(`/api/tv/[^/]+/assets/${first}/image$`));

	// The TV has no cookie: the address alone opens the photo, and nothing else.
	const image = await tv.get(shown);
	expect(image.status()).toBe(200);
	expect(image.headers()['content-type']).toBe('image/jpeg');
	expect((await tv.get(shown.replace(first, second))).status()).toBe(404);
	expect((await tv.get(shown.replace(/image$/, 'original'))).status()).toBe(403);

	// Stopping takes the token away, also from a TV that kept the address.
	await page
		.getByRole('region', { name: /Playing on/ })
		.getByRole('button', { name: 'Stop' })
		.click();
	await expect(page.getByRole('region', { name: /Playing on/ })).toHaveCount(0);
	await expect.poll(async () => (await tv.get(shown)).status(), { timeout: 10_000 }).toBe(404);
	expect(await page.evaluate(() => (window as unknown as { endedOnTv?: boolean }).endedOnTv)).toBe(
		true
	);

	// From a slideshow, which the TV follows.
	const album = await (
		await page.request.post('/api/albums', { data: { title: `Cast ${Date.now()}` } })
	).json();
	await page.request.post(`/api/albums/${album.id}/assets`, { data: { ids: [first, second] } });
	await page.goto(`/albums/${album.id}`);
	await page.getByRole('button', { name: 'Slideshow' }).click();
	const show = page.getByRole('dialog', { name: 'Slideshow' });
	await expect(show.getByText('1 / 2')).toBeVisible();
	await show.press(' ');
	await show.getByRole('button', { name: 'Play on TV' }).click();
	await show.getByRole('menuitem', { name: /Chromecast/ }).click();
	// A new page, so the stand-in has started its list again.
	await expect.poll(async () => (await loaded()).length).toBe(1);
	await show.getByRole('button', { name: 'Next', exact: true }).click();
	await expect(show.getByText('2 / 2')).toBeVisible();
	await expect.poll(async () => (await loaded()).length).toBe(2);
	const [fromShow, next] = await loaded();
	expect(next).not.toBe(fromShow);
	expect(next.split('/assets/')[0]).toBe(fromShow.split('/assets/')[0]);
	expect([fromShow, next].map((url) => url.split('/assets/')[1].split('/')[0]).sort()).toEqual(
		[first, second].sort()
	);
	expect((await tv.get(next)).status()).toBe(200);
	await show
		.getByRole('region', { name: /Playing on/ })
		.getByRole('button', { name: 'Stop' })
		.click();
	await expect.poll(async () => (await tv.get(next)).status(), { timeout: 10_000 }).toBe(404);
	await page.request.delete(`/api/albums/${album.id}`);
	await tv.dispose();
});
