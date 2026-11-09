import { describe, expect, it } from 'vitest';
import type { DuplicateGroup } from '#lib/api.ts';
import { choiceOf, notesOf, reasonOf } from './duplicates.ts';

const en = (_hr: string, en: string) => en;

function item(id: string, extra: Partial<DuplicateGroup['items'][number]> = {}) {
	return {
		id,
		originalName: `${id}.jpg`,
		sizeBytes: 100,
		ratio: 1,
		localAt: '2024-07-05T10:00:00',
		width: 1000,
		height: 1000,
		favorite: false,
		original: false,
		resaved: false,
		hasDate: true,
		hasLocation: false,
		hasCaption: false,
		...extra
	};
}

const group: DuplicateGroup = {
	keepId: 'a',
	exact: false,
	freedBytes: 200,
	items: [item('a', { original: true }), item('b', { resaved: true }), item('c')]
};

describe('resolving duplicates', () => {
	it('keeps the proposal and lets the unticked go', () => {
		expect(choiceOf(group, (id) => id === 'a')).toEqual({ keepId: 'a', trashIds: ['b', 'c'] });
	});
	it('keeps another one when the proposal is unticked, and leaves a second kept one alone', () => {
		expect(choiceOf(group, (id) => id !== 'a')).toEqual({ keepId: 'b', trashIds: ['a'] });
	});
	it('does nothing when nothing or everything is kept', () => {
		expect(choiceOf(group, () => false)).toBeUndefined();
		expect(choiceOf(group, () => true)).toBeUndefined();
	});
	it('says why one is proposed and how the copies differ', () => {
		expect(reasonOf(group, en)).toBe("the camera's original");
		expect(notesOf(group.items[1], en)).toEqual(['Saved again by an app']);
		expect(notesOf(item('d', { favorite: true, hasDate: false }), en)).toEqual([
			'Favorite',
			'No date'
		]);
	});
});
