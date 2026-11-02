import { describe, expect, it } from 'vitest';
import { formatBytes, initialsOf } from './api.ts';

describe('initialsOf', () => {
	it('uses the first and last names', () => {
		expect(initialsOf('Demo korisnik')).toBe('DK');
		expect(initialsOf('Ana Maria Horvat')).toBe('AH');
	});

	it('uses two letters of a single name', () => {
		expect(initialsOf('admin')).toBe('AD');
	});
});

describe('formatBytes', () => {
	it('picks a readable unit', () => {
		expect(formatBytes(512)).toBe('512 B');
		expect(formatBytes(1536)).toBe('1.5 KB');
		expect(formatBytes(3 * 1024 ** 3)).toBe('3.0 GB');
	});
});
