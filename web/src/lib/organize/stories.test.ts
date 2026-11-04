import { describe, expect, it } from 'vitest';
import { yearsAgo } from './stories.ts';

describe('yearsAgo', () => {
	it('counts years, and never goes below zero', () => {
		expect(yearsAgo(2022, 2026)).toBe(4);
		expect(yearsAgo(2027, 2026)).toBe(0);
	});
});
