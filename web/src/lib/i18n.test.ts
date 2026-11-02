import { describe, expect, it } from 'vitest';
import { parseLang } from './i18n.svelte';

describe('parseLang', () => {
	it('prefers a stored choice over the browser language', () => {
		expect(parseLang('en', 'hr-HR')).toBe('en');
		expect(parseLang('hr', 'en-US')).toBe('hr');
	});

	it('uses Croatian for a Croatian browser', () => {
		expect(parseLang(null, 'hr-HR')).toBe('hr');
	});

	it('falls back to English for anything else', () => {
		expect(parseLang(null, 'de-DE')).toBe('en');
		expect(parseLang('xx', undefined)).toBe('en');
	});
});
