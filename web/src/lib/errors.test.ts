import { describe, expect, it } from 'vitest';
import { ApiError } from './api.ts';
import { errorKind, kindOfFailure } from './errors.ts';

describe('errorKind', () => {
	it('tells a missing page from a server that is down or broken', () => {
		expect(errorKind(404)).toBe('notFound');
		expect(errorKind(503)).toBe('unavailable');
		expect(errorKind(502)).toBe('unavailable');
		expect(errorKind(500)).toBe('server');
		expect(errorKind(500, false)).toBe('offline');
	});
});

describe('kindOfFailure', () => {
	it('reads what the server answered, or that nothing answered', () => {
		expect(kindOfFailure(new ApiError(503, 'maintenance'))).toBe('unavailable');
		expect(kindOfFailure(new ApiError(404, 'gone'))).toBe('notFound');
		expect(kindOfFailure(new TypeError('Failed to fetch'))).toBe('offline');
		expect(kindOfFailure(new Error('boom'))).toBe('server');
		expect(kindOfFailure(new ApiError(500, 'x'), false)).toBe('offline');
	});
});
