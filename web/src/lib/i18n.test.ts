import { describe, expect, it } from 'vitest';
import en from './i18n/en.json';
import hr from './i18n/hr.json';
import { dateLocale, format, parseLang, setLang } from './i18n.svelte.ts';

describe('parseLang', () => {
	it('uses a stored choice', () => {
		expect(parseLang('hr')).toBe('hr');
		expect(parseLang('de')).toBe('de');
		expect(parseLang('en')).toBe('en');
	});

	it('defaults to English', () => {
		expect(parseLang(null)).toBe('en');
		expect(parseLang('xx')).toBe('en');
	});
});

describe('format', () => {
	it('fills in what it is given', () => {
		expect(format('Showing {shown} of {total}.', { shown: 3, total: 1200 }, 'en')).toBe(
			'Showing 3 of 1,200.'
		);
	});

	it('picks the Croatian form for the number', () => {
		const text = '{count, plural, one {# stavka} few {# stavke} other {# stavki}}';
		expect(format(text, { count: 1 }, 'hr')).toBe('1 stavka');
		expect(format(text, { count: 3 }, 'hr')).toBe('3 stavke');
		expect(format(text, { count: 5 }, 'hr')).toBe('5 stavki');
		expect(format(text, { count: 21 }, 'hr')).toBe('21 stavka');
	});

	it('and the English one', () => {
		const text = '{count, plural, one {# item} other {# items}}';
		expect(format(text, { count: 1 }, 'en')).toBe('1 item');
		expect(format(text, { count: 2 }, 'en')).toBe('2 items');
	});
});

describe('the catalogs', () => {
	it('have Croatian for every English text', () => {
		const missing = Object.keys(en).filter((key) => !(key in hr));
		expect(missing).toEqual([]);
	});

	it('use in Croatian only what the code gives', () => {
		const names = (text: string) => new Set([...text.matchAll(/\{(\w+)[,}]/g)].map((m) => m[1]));
		// The code gives both of these; each language says it its own way.
		const extra: Record<string, string[]> = {
			'memories.onThisDayYearsYears': ['year'],
			'qRSignInDialog.valueIsSignedInIt': ['value2']
		};
		const unknown = Object.entries(hr).flatMap(([key, text]) => {
			const given = new Set([
				...names((en as Record<string, string>)[key] ?? ''),
				...(extra[key] ?? [])
			]);
			return [...names(text)].filter((name) => !given.has(name)).map((name) => `${key}: ${name}`);
		});
		expect(unknown).toEqual([]);
	});
});

describe('locale', () => {
	it('writes dates and numbers the way each language does', async () => {
		await setLang('de');
		expect(dateLocale()).toBe('de-DE');
		await setLang('sl');
		expect(dateLocale()).toBe('sl-SI');
		await setLang('en');
		expect(dateLocale()).toBe('en-GB');
	});
});
