import { describe, expect, it } from 'vitest';
import type { CleanupItem } from '#lib/api.ts';
import { lengthOf, ticked, titleOf } from './cleanup.ts';

const item = (extra: Partial<CleanupItem>): CleanupItem => ({
	id: 'a',
	originalName: 'a.png',
	sizeBytes: 1,
	kind: 'photo',
	ratio: 1,
	localAt: '2024-07-05T10:00:00',
	favorite: false,
	inAlbum: false,
	...extra
});

describe('clean up', () => {
	it('ticks all but favorites and photos in albums', () => {
		expect(ticked(item({}))).toBe(true);
		expect(ticked(item({ favorite: true }))).toBe(false);
		expect(ticked(item({ inAlbum: true }))).toBe(false);
	});
	it('names the kinds', () => {
		expect(titleOf('largeVideos')).toBe('Large videos');
	});
	it('says how long a video is', () => {
		expect(lengthOf(65_000)).toBe('1:05');
		expect(lengthOf(3_725_000)).toBe('1:02:05');
	});
});
