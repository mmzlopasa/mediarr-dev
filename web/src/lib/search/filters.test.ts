import { describe, expect, it } from 'vitest';
import { chipsFor, hasSearch, withoutChip } from './filters.ts';

const tr = (_hr: string, en: string) => en;
const day = (iso: string) => iso;

describe('search filters', () => {
	it('knows when there is something to search for', () => {
		expect(hasSearch(new URLSearchParams(''))).toBe(false);
		expect(hasSearch(new URLSearchParams('q=%20'))).toBe(false);
		expect(hasSearch(new URLSearchParams('q=dog'))).toBe(true);
		expect(hasSearch(new URLSearchParams('type=video'))).toBe(true);
	});

	it('marks what was found in the words apart from what was chosen', () => {
		const params = new URLSearchParams('q=Ana%20Hvar%20dog&camera=X-T5');
		const chips = chipsFor(
			{ people: [{ id: 'p1', name: 'Ana' }], place: 'Hvar', camera: 'X-T5', words: 'dog' },
			params,
			tr,
			day
		);
		expect(chips.map((chip) => [chip.label, chip.found])).toEqual([
			['Ana', true],
			['Hvar', true],
			['X-T5', false]
		]);
	});

	it('drops a chosen filter, and searches a found one as a word', () => {
		const filters = { people: [{ id: 'p1', name: 'Ana' }], place: 'Hvar', camera: 'X-T5' };
		const params = new URLSearchParams('q=Ana%20Hvar&camera=X-T5');
		const [ana, hvar, camera] = chipsFor(filters, params, tr, day);
		expect(withoutChip(params, camera, filters).has('camera')).toBe(false);
		const plain = withoutChip(params, hvar, filters);
		expect(plain.get('plain')).toBe('true');
		expect(plain.getAll('person')).toEqual(['p1']);
		expect(plain.has('place')).toBe(false);
		expect(withoutChip(params, ana, filters).getAll('person')).toEqual([]);
	});
});
