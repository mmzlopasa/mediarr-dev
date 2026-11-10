import type { CastMedia } from '#lib/api.ts';
import type { Key } from '#lib/i18n.svelte.ts';

/** Where a photo can go from this browser, and if it cannot, why not. */
export type TvTarget = 'chromecast' | 'airplay' | 'dlna';
export type TvChoice = { target: TvTarget; available: boolean; note: Key };

export type BrowserCaps = {
	/** Chrome allows its Cast sender only on HTTPS (or localhost). */
	secure: boolean;
	/** Chrome or a browser built on it, which has the Cast sender. */
	chrome: boolean;
	/** Safari, which can send a video to an Apple TV. */
	airplay: boolean;
	kind: 'photo' | 'video';
};

export function browserCaps(kind: 'photo' | 'video'): BrowserCaps {
	const w = window as unknown as {
		chrome?: unknown;
		WebKitPlaybackTargetAvailabilityEvent?: unknown;
	};
	return {
		secure: window.isSecureContext,
		chrome: !!w.chrome && /Chrome|Chromium|Edg\//.test(navigator.userAgent),
		airplay: !!w.WebKitPlaybackTargetAvailabilityEvent,
		kind
	};
}

/** What the "Play on TV" menu offers. Everything that does not work here says so, and why. */
export function tvChoices(caps: BrowserCaps): TvChoice[] {
	const chromecast: TvChoice = !caps.chrome
		? { target: 'chromecast', available: false, note: 'cast.chromecastNeedsChrome' }
		: !caps.secure
			? { target: 'chromecast', available: false, note: 'cast.chromecastNeedsHttps' }
			: { target: 'chromecast', available: true, note: 'cast.chromecastNote' };
	const airplay: TvChoice = !caps.airplay
		? { target: 'airplay', available: false, note: 'cast.airplayNeedsSafari' }
		: caps.kind === 'video'
			? { target: 'airplay', available: true, note: 'cast.airplayNote' }
			: { target: 'airplay', available: false, note: 'cast.airplayPhotosMirroring' };
	return [chromecast, airplay, { target: 'dlna', available: false, note: 'cast.dlnaInTheApp' }];
}

/** The paths a later answer gives carry a placeholder: the token is only known to whoever started. */
export function withToken(path: string, token: string) {
	return path.replace('{token}', encodeURIComponent(token));
}

export function absolute(origin: string, path: string) {
	return new URL(path, origin).toString();
}

/** What a TV plays for an asset: a video's stream if it has one, else its file, else the picture. */
export function tvSource(media: CastMedia, token: string): { url: string; type: string } {
	if (media.kind === 'video' && media.hls) {
		return { url: withToken(media.hls, token), type: 'application/vnd.apple.mpegurl' };
	}
	if (media.kind === 'video' && media.file) {
		return { url: withToken(media.file, token), type: media.mimeType || 'video/mp4' };
	}
	return { url: withToken(media.image, token), type: 'image/jpeg' };
}
