import { describe, expect, it } from 'vitest';
import { absolute, tvChoices, tvSource, withToken } from './cast.ts';

const chromeOnHttp = { secure: false, chrome: true, airplay: false, kind: 'photo' as const };

describe('tvChoices', () => {
	it('does not offer Cast on plain HTTP, and says why', () => {
		const cast = tvChoices(chromeOnHttp).find((choice) => choice.target === 'chromecast');
		expect(cast).toEqual({
			target: 'chromecast',
			available: false,
			note: 'cast.chromecastNeedsHttps'
		});
	});

	it('offers Cast in Chrome on HTTPS', () => {
		const cast = tvChoices({ ...chromeOnHttp, secure: true })[0];
		expect(cast.available).toBe(true);
	});

	it('sends Cast users without Chrome to Chrome or the app', () => {
		expect(tvChoices({ ...chromeOnHttp, chrome: false, secure: true })[0].note).toBe(
			'cast.chromecastNeedsChrome'
		);
	});

	it('offers AirPlay in Safari for videos only', () => {
		const safari = { secure: false, chrome: false, airplay: true };
		const video = tvChoices({ ...safari, kind: 'video' }).find((c) => c.target === 'airplay');
		const photo = tvChoices({ ...safari, kind: 'photo' }).find((c) => c.target === 'airplay');
		expect(video?.available).toBe(true);
		expect(photo).toEqual({
			target: 'airplay',
			available: false,
			note: 'cast.airplayPhotosMirroring'
		});
	});

	it('never offers DLNA in a browser', () => {
		for (const secure of [true, false]) {
			const dlna = tvChoices({ ...chromeOnHttp, secure }).find((c) => c.target === 'dlna');
			expect(dlna?.available).toBe(false);
		}
	});
});

describe('tvSource', () => {
	const id = '00000000-0000-4000-8000-000000000001';
	it('fills in the token of a later answer', () => {
		expect(withToken(`/api/tv/{token}/assets/${id}/image`, 'a+b')).toBe(
			`/api/tv/a%2Bb/assets/${id}/image`
		);
	});

	it('plays the stream of a video when it has one, else its file', () => {
		const video = {
			id,
			kind: 'video' as const,
			image: '/api/tv/{token}/assets/x/image',
			file: '/api/tv/{token}/assets/x/original',
			mimeType: 'video/quicktime'
		};
		expect(tvSource(video, 't')).toEqual({
			url: '/api/tv/t/assets/x/original',
			type: 'video/quicktime'
		});
		expect(tvSource({ ...video, hls: '/api/tv/{token}/assets/x/video/master.m3u8' }, 't')).toEqual({
			url: '/api/tv/t/assets/x/video/master.m3u8',
			type: 'application/vnd.apple.mpegurl'
		});
		expect(tvSource({ id, kind: 'photo', image: '/api/tv/t/assets/x/image' }, 't').type).toBe(
			'image/jpeg'
		);
	});

	it('gives the TV a whole address on the server the page came from', () => {
		expect(absolute('http://192.168.1.5:9851', '/api/tv/t/assets/x/image')).toBe(
			'http://192.168.1.5:9851/api/tv/t/assets/x/image'
		);
	});
});
