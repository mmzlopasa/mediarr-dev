import { describe, expect, it } from 'vitest';
import {
	DEFAULT_SETTINGS,
	loadSettings,
	nextIndex,
	playOrder,
	saveSettings,
	shownTransition
} from './slideshow.ts';

const items = ['a', 'b', 'c', 'd', 'e'].map((id) => ({ id }));

describe('slideshow', () => {
	it('starts from the open photo and keeps the order of the list', () => {
		expect(playOrder(items, 'c', false).map((item) => item.id)).toEqual(['c', 'd', 'e', 'a', 'b']);
		expect(playOrder(items, 'missing', false).map((item) => item.id)).toEqual([
			'a',
			'b',
			'c',
			'd',
			'e'
		]);
	});

	it('shuffled, still starts from the open photo and shows each once', () => {
		let seed = 0.37;
		const random = () => (seed = ((seed * 9301 + 49297) % 233280) / 233280);
		const order = playOrder(items, 'c', true, random).map((item) => item.id);
		expect(order[0]).toBe('c');
		expect([...order].sort()).toEqual(['a', 'b', 'c', 'd', 'e']);
		expect(playOrder([], 'x', true)).toEqual([]);
	});

	it('goes round again only when it loops', () => {
		expect(nextIndex(1, 5, false)).toBe(2);
		expect(nextIndex(4, 5, false)).toBeUndefined();
		expect(nextIndex(4, 5, true)).toBe(0);
		expect(nextIndex(0, 5, true, -1)).toBe(4);
		expect(nextIndex(0, 5, false, -1)).toBeUndefined();
		expect(nextIndex(0, 0, true)).toBeUndefined();
	});

	it('keeps its settings, and takes the defaults for anything wrong', () => {
		const kept = new Map<string, string>();
		const storage = {
			getItem: (key: string) => kept.get(key) ?? null,
			setItem: (key: string, value: string) => void kept.set(key, value)
		};
		expect(loadSettings(storage)).toEqual(DEFAULT_SETTINGS);
		saveSettings(storage, {
			seconds: 10,
			transition: 'zoom',
			shuffle: true,
			loop: false,
			caption: true
		});
		expect(loadSettings(storage)).toEqual({
			seconds: 10,
			transition: 'zoom',
			shuffle: true,
			loop: false,
			caption: true
		});
		kept.set('mediarr_slideshow', '{"seconds":7,"transition":"spin","shuffle":"yes"}');
		expect(loadSettings(storage)).toEqual(DEFAULT_SETTINGS);
		kept.set('mediarr_slideshow', 'not json');
		expect(loadSettings(storage)).toEqual(DEFAULT_SETTINGS);
	});

	it('only fades when the system asks for less motion', () => {
		expect(shownTransition('zoom', true)).toBe('fade');
		expect(shownTransition('slide', true)).toBe('fade');
		expect(shownTransition('none', true)).toBe('none');
		expect(shownTransition('zoom', false)).toBe('zoom');
	});
});
