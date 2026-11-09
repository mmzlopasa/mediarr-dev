import { describe, expect, it } from 'vitest';
import type { LibraryExport } from '#lib/api.ts';
import { EXPORT_STATUS, exportBusy, exportPartUrl, exportPct } from './exports.ts';

const entry = (changes: Partial<LibraryExport> = {}): LibraryExport => ({
	id: 'e1',
	userId: 'u1',
	userEmail: 'me@example.com',
	status: 'running',
	startedByAdmin: false,
	startedBy: 'Me',
	totalFiles: 10,
	totalBytes: 1000,
	doneFiles: 3,
	doneBytes: 250,
	missing: 0,
	lastError: '',
	createdAt: '2026-11-09T10:00:00Z',
	parts: [],
	canDownload: true,
	...changes
});

describe('exports', () => {
	it('count their progress by bytes, and by files before the bytes are known', () => {
		expect(exportPct(entry())).toBe(25);
		expect(exportPct(entry({ totalBytes: 0 }))).toBe(30);
		expect(exportPct(entry({ totalBytes: 0, totalFiles: 0 }))).toBe(0);
		expect(exportPct(entry({ status: 'done', doneBytes: 0 }))).toBe(100);
	});

	it('are asked for again only while one runs', () => {
		expect(exportBusy([entry()])).toBe(true);
		expect(exportBusy([entry({ status: 'done' }), entry({ status: 'cancelled' })])).toBe(false);
	});

	it('name every state and each part', () => {
		expect(Object.keys(EXPORT_STATUS).sort()).toEqual([
			'cancelled',
			'done',
			'failed',
			'removed',
			'running'
		]);
		expect(exportPartUrl(entry(), 2)).toBe('/api/exports/e1/parts/2');
	});
});
