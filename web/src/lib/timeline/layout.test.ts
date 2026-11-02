import { describe, expect, it } from 'vitest';
import type { TimelineItem } from '#lib/api.ts';
import {
	estimateMonthHeight,
	formatDay,
	formatMonth,
	GAP,
	justify,
	layoutMonth,
	rowsInRange
} from './layout.ts';

const item = (ratio: number, localAt = '2024-07-15T12:00:00', id = 'a'): TimelineItem => ({
	id,
	kind: 'photo',
	ratio,
	isFavorite: false,
	localAt
});

describe('justify', () => {
	it('fills the width exactly on complete rows', () => {
		const rows = justify(
			Array.from({ length: 20 }, () => item(1.5)),
			0,
			1000,
			200
		);
		for (const row of rows.slice(0, -1)) {
			const last = row.tiles[row.tiles.length - 1];
			expect(last.x + last.width).toBeCloseTo(1000, 3);
		}
	});

	it('does not stretch an unfinished last row', () => {
		const [row] = justify([item(1)], 0, 1000, 200);
		expect(row.height).toBe(200);
		expect(row.tiles[0].width).toBe(200);
	});

	it('keeps a single very wide panorama inside the width', () => {
		const [row] = justify([item(20)], 0, 300, 110);
		expect(row.tiles[0].width).toBeLessThanOrEqual(300.001);
	});

	it('survives a broken ratio', () => {
		for (const ratio of [0, -1, NaN, Infinity]) {
			const [row] = justify([item(ratio)], 0, 300, 110);
			expect(row.tiles[0].width).toBeGreaterThan(0);
			expect(row.height).toBeGreaterThan(0);
		}
	});

	it('leaves the gap between tiles and numbers them from the start', () => {
		const [row] = justify([item(1), item(1), item(1)], 7, 310, 100);
		expect(row.tiles[1].x - row.tiles[0].width).toBeCloseTo(GAP, 3);
		expect(row.tiles.map((tile) => tile.index)).toEqual([7, 8, 9]);
	});
});

describe('layoutMonth', () => {
	const items = [
		item(1, '2024-07-15T12:00:00'),
		item(1, '2024-07-15T09:00:00'),
		item(1, '2024-07-14T23:59:00')
	];

	it('adds a header for the month and for each local day', () => {
		const layout = layoutMonth(items, 1000, 'July', (localAt) => localAt.slice(0, 10));
		const headers = layout.rows.filter((row) => row.type !== 'tiles');
		expect(headers.map((row) => ('label' in row ? row.label : ''))).toEqual([
			'July',
			'2024-07-15',
			'2024-07-14'
		]);
	});

	it('orders rows so that nothing overlaps', () => {
		const layout = layoutMonth(items, 1000, 'July', () => 'day');
		for (let i = 1; i < layout.rows.length; i++) {
			expect(layout.rows[i].top).toBeGreaterThanOrEqual(
				layout.rows[i - 1].top + layout.rows[i - 1].height
			);
		}
		const last = layout.rows[layout.rows.length - 1];
		expect(layout.height).toBeGreaterThanOrEqual(last.top + last.height);
	});

	it('handles 2,000 items quickly', () => {
		const many = Array.from({ length: 2000 }, (_, i) => item(1 + (i % 3)));
		const started = performance.now();
		layoutMonth(many, 1200, 'July', () => 'day');
		expect(performance.now() - started).toBeLessThan(50);
	});
});

describe('rowsInRange', () => {
	const rows = Array.from({ length: 100 }, (_, i) => ({
		type: 'month' as const,
		top: i * 100,
		height: 90,
		label: String(i)
	}));

	it('finds only rows that intersect the range', () => {
		// The row at 200 ends at 290, so it is still in view from 250.
		const found = rowsInRange(rows, 250, 450);
		expect(found.map((row) => row.top)).toEqual([200, 300, 400]);
	});

	it('returns nothing outside the list', () => {
		expect(rowsInRange(rows, 50000, 60000)).toEqual([]);
	});
});

describe('estimateMonthHeight', () => {
	it('grows with the count and is never empty', () => {
		expect(estimateMonthHeight(1000, 1000)).toBeGreaterThan(estimateMonthHeight(10, 1000));
		expect(estimateMonthHeight(1, 300)).toBeGreaterThan(0);
	});
});

describe('dates', () => {
	it('shows the wall clock of the capture, in any browser time zone', () => {
		expect(formatDay('2024-08-01T00:30:00', 'en-GB')).toContain('1 August');
		expect(formatMonth('2024-08', 'en-GB')).toBe('August 2024');
	});
});
