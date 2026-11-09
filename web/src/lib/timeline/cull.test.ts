import { describe, expect, it } from 'vitest';
import {
	actualSizeScale,
	chunks,
	keyAction,
	preloadIds,
	toggleCompared,
	withPick
} from './cull.ts';

describe('going through a shoot', () => {
	it('knows its keys', () => {
		expect(keyAction('P')).toEqual({ type: 'pick', value: 1 });
		expect(keyAction('x')).toEqual({ type: 'pick', value: -1 });
		expect(keyAction('u')).toEqual({ type: 'pick', value: 0 });
		expect(keyAction('4')).toEqual({ type: 'rate', value: 4 });
		expect(keyAction('ArrowRight')).toEqual({ type: 'move', by: 1 });
		expect(keyAction('z')).toEqual({ type: 'zoom' });
		expect(keyAction('6')).toBeUndefined();
		expect(keyAction('q')).toBeUndefined();
	});

	it('has the next photos ready, the nearest first', () => {
		expect(preloadIds(['a', 'b', 'c', 'd', 'e', 'f'], 1)).toEqual(['c', 'd', 'e', 'a']);
		expect(preloadIds(['a', 'b'], 1)).toEqual(['a']);
	});

	it('cuts long lists for the server', () => {
		expect(chunks([1, 2, 3], 2)).toEqual([[1, 2], [3]]);
		expect(chunks([])).toEqual([]);
	});

	it('compares up to four photos', () => {
		expect(toggleCompared(['a'], 'b')).toEqual(['a', 'b']);
		expect(toggleCompared(['a', 'b'], 'a')).toEqual(['b']);
		expect(toggleCompared(['a', 'b', 'c', 'd'], 'e')).toEqual(['a', 'b', 'c', 'd']);
	});

	it('finds the photos with a mark, in order', () => {
		const marks = {
			a: { pick: 1, rating: 0 },
			b: { pick: -1, rating: 0 },
			c: { pick: 1, rating: 3 }
		};
		expect(withPick(['c', 'b', 'a', 'd'], marks, 1)).toEqual(['c', 'a']);
	});

	it('works out 100 % from the photo and the space', () => {
		expect(actualSizeScale({ width: 4000, height: 3000 }, { width: 1000, height: 1000 })).toBe(4);
		expect(actualSizeScale({ width: 500, height: 400 }, { width: 1000, height: 1000 })).toBe(1);
		expect(actualSizeScale({}, { width: 1000, height: 1000 })).toBe(2);
	});
});
