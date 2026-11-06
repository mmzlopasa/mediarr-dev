import { describe, expect, it } from 'vitest';
import { describeAgent, since } from './agent.ts';

describe('describeAgent', () => {
	it('names the browser and the system', () => {
		expect(
			describeAgent(
				'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36 Edg/156.0.0.0'
			)
		).toEqual({ program: 'Edge', system: 'Windows', phone: false });
		expect(
			describeAgent(
				'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36'
			)
		).toEqual({ program: 'Headless Chrome', system: 'Linux', phone: false });
		expect(
			describeAgent(
				'Mozilla/5.0 (iPhone; CPU iPhone OS 19_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/19.0 Mobile/15E148 Safari/604.1'
			)
		).toEqual({ program: 'Safari', system: 'iPhone', phone: true });
		expect(describeAgent('Dart/3.9 (dart:io)')).toEqual({
			program: 'Mediarr app',
			system: '',
			phone: true
		});
	});

	it('leaves out what it cannot tell', () => {
		expect(describeAgent('')).toEqual({ program: '', system: '', phone: false });
	});
});

describe('since', () => {
	it('picks the largest fitting unit', () => {
		const now = new Date('2026-11-06T12:00:00Z');
		expect(since(new Date('2026-11-06T09:00:00Z'), now)).toBe('3 hours ago');
		expect(since(new Date('2026-11-04T12:00:00Z'), now)).toBe('2 days ago');
		expect(since(new Date('2026-11-06T11:59:58Z'), now)).toBe('2 seconds ago');
	});
});
