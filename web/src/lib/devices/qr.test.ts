import { describe, expect, it } from 'vitest';
import { left, onlyHere, withServer } from './qr.ts';

describe('sign-in codes', () => {
	it('carry the address a phone can reach', () => {
		const link = 'mediarr://sign-in?code=K7QM2XPA&server=http%3A%2F%2F127.0.0.1%3A9851';
		const changed = new URL(withServer(link, 'http://192.168.1.20:9851/ '));
		expect(changed.searchParams.get('server')).toBe('http://192.168.1.20:9851');
		expect(changed.searchParams.get('code')).toBe('K7QM2XPA');
	});
	it('know an address only this computer reaches', () => {
		expect(onlyHere('http://127.0.0.1:9851')).toBe(true);
		expect(onlyHere('http://localhost:9851')).toBe(true);
		expect(onlyHere('http://192.168.1.20:9851')).toBe(false);
		expect(onlyHere('https://foto.example.com')).toBe(false);
	});
	it('count down', () => {
		const now = Date.parse('2026-11-09T10:00:00Z');
		expect(left('2026-11-09T10:04:05Z', now)).toBe('4:05');
		expect(left('2026-11-09T09:59:00Z', now)).toBe('0:00');
	});
});
