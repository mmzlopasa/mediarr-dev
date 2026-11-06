import { describe, expect, it } from 'vitest';
import { fileNameFrom } from './share.ts';

describe('fileNameFrom', () => {
	it('reads the name the server gives a file', () => {
		expect(fileNameFrom('attachment; filename=beach.jpg', 'x')).toBe('beach.jpg');
		expect(fileNameFrom('attachment; filename="Summer day.HEIC"', 'x')).toBe('Summer day.HEIC');
		expect(fileNameFrom("attachment; filename*=UTF-8''%C5%BEuta%20ku%C4%87a.jpg", 'x')).toBe(
			'žuta kuća.jpg'
		);
		expect(fileNameFrom(null, 'abc')).toBe('abc');
	});
});
