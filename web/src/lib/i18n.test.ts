import { describe, expect, it } from 'vitest';
import { parseLang } from './i18n.svelte.ts';

describe('parseLang', () => {
	it('uses a stored choice', () => {
		expect(parseLang('hr')).toBe('hr');
		expect(parseLang('en')).toBe('en');
	});

	it('defaults to English', () => {
		expect(parseLang(null)).toBe('en');
		expect(parseLang('xx')).toBe('en');
	});
});
