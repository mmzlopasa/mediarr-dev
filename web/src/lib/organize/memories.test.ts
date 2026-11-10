import { describe, expect, it } from 'vitest';
import { setLang } from '#lib/i18n.svelte.ts';
import type { Memory } from '#lib/api.ts';
import { memoryDates, memoryTitle } from './memories.ts';

const memory = (over: Partial<Memory>): Memory =>
	({ kind: 'trip', key: 'x', title: '', items: [], ...over }) as Memory;

describe('memoryTitle', () => {
	const trip = memory({ kind: 'trip', titleParams: { place: 'Split', month: 7, year: 2024 } });

	it('names a trip by place, month and year, with the month in the language', () => {
		setLang('hr');
		expect(memoryTitle(trip)).toBe('Split, srpanj 2024');
		setLang('sl');
		expect(memoryTitle(trip)).toBe('Split, julij 2024');
		setLang('de');
		expect(memoryTitle(trip)).toBe('Split, Juli 2024');
		setLang('en');
		expect(memoryTitle(trip)).toBe('Split, July 2024');
	});

	it('does not write a year as a number with a separator', () => {
		setLang('en');
		const year = memory({ kind: 'year_review', titleParams: { year: 2024 } });
		expect(memoryTitle(year)).toBe('2024 in photos');
	});

	it('uses the name it is given', () => {
		setLang('hr');
		const person = memory({ kind: 'birthday', titleParams: { person: 'Ana' } });
		expect(memoryTitle(person)).toBe('Rođendan: Ana');
		expect(memoryTitle(memory({ kind: 'month_ago' }))).toBe('Prije mjesec dana');
		setLang('en');
	});
});

describe('memoryDates', () => {
	it('writes a span of days in the language, not as the server sends it', () => {
		const trip = memory({ title: '2024-07-12 – 2024-07-19' });
		expect(memoryDates(trip, 'en-GB')).toMatch(/^12\s*–\s*19 Jul 2024$/);
		expect(memoryDates(trip, 'de-DE')).toMatch(/^12\.\s*[–-]\s*19\.\s*0?7\.\s*2024$/);
	});

	it('writes one day, and leaves a year alone', () => {
		expect(memoryDates(memory({ title: '2024-11-10' }), 'en-GB')).toBe('10 Nov 2024');
		expect(memoryDates(memory({ title: '2025' }), 'en-GB')).toBe('2025');
	});
});
