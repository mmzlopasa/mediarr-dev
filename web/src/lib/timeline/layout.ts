import type { TimelineItem } from '#lib/api.ts';

export const GAP = 3;
export const MONTH_HEADER = 112;
export const DAY_HEADER = 44;
const MIN_RATIO = 0.4;
const MAX_RATIO = 4;
const AVERAGE_RATIO = 1.4;

export type Tile = { item: TimelineItem; index: number; x: number; width: number };
export type Row =
	| { type: 'month'; top: number; height: number; label: string }
	| { type: 'day'; top: number; height: number; label: string }
	| { type: 'tiles'; top: number; height: number; tiles: Tile[] };

export type MonthLayout = { height: number; rows: Row[]; items: TimelineItem[] };

export function rowHeightFor(width: number) {
	if (width < 600) return 110;
	if (width < 1100) return 170;
	return 220;
}

const clampRatio = (ratio: number) =>
	Math.min(MAX_RATIO, Math.max(MIN_RATIO, ratio > 0 && Number.isFinite(ratio) ? ratio : 1));

/** Splits items into rows that fill the width exactly, except for an unfinished last row. */
export function justify(items: TimelineItem[], start: number, width: number, target: number) {
	const rows: { height: number; tiles: Tile[] }[] = [];
	let current: { item: TimelineItem; index: number; ratio: number }[] = [];
	let sum = 0;

	const close = (fill: boolean) => {
		const free = width - GAP * (current.length - 1);
		const height = fill ? free / sum : Math.min(target, free / sum);
		let x = 0;
		const tiles = current.map(({ item, index, ratio }) => {
			const tile = { item, index, x, width: ratio * height };
			x += tile.width + GAP;
			return tile;
		});
		rows.push({ height, tiles });
		current = [];
		sum = 0;
	};

	items.forEach((item, offset) => {
		const ratio = clampRatio(item.ratio);
		current.push({ item, index: start + offset, ratio });
		sum += ratio;
		if (sum * target + GAP * (current.length - 1) >= width) close(true);
	});
	if (current.length > 0) close(false);
	return rows;
}

/** Calculates a whole month from aspect ratios alone, so nothing moves as images load. */
export function layoutMonth(
	items: TimelineItem[],
	width: number,
	monthLabel: string,
	dayLabel: (localAt: string) => string
): MonthLayout {
	const target = rowHeightFor(width);
	const rows: Row[] = [{ type: 'month', top: 0, height: MONTH_HEADER, label: monthLabel }];
	let top = MONTH_HEADER;
	let start = 0;

	while (start < items.length) {
		const day = items[start].localAt.slice(0, 10);
		let end = start + 1;
		while (end < items.length && items[end].localAt.slice(0, 10) === day) end += 1;

		rows.push({ type: 'day', top, height: DAY_HEADER, label: dayLabel(items[start].localAt) });
		top += DAY_HEADER;
		for (const row of justify(items.slice(start, end), start, width, target)) {
			rows.push({ type: 'tiles', top, height: row.height, tiles: row.tiles });
			top += row.height + GAP;
		}
		start = end;
	}
	return { height: top, rows, items };
}

/** Height of a month that has not loaded yet, close enough to keep the scrollbar steady. */
export function estimateMonthHeight(count: number, width: number) {
	const target = rowHeightFor(width);
	const perRow = Math.max(1, width / (AVERAGE_RATIO * target + GAP));
	const rows = Math.ceil(count / perRow);
	const days = Math.min(count, 12);
	return MONTH_HEADER + days * DAY_HEADER + rows * (target + GAP);
}

/** The rows of a sorted list that intersect a vertical range, found by binary search. */
export function rowsInRange(rows: Row[], from: number, to: number) {
	let low = 0;
	let high = rows.length;
	while (low < high) {
		const middle = (low + high) >> 1;
		if (rows[middle].top + rows[middle].height < from) low = middle + 1;
		else high = middle;
	}
	const out: Row[] = [];
	for (let i = low; i < rows.length && rows[i].top <= to; i++) out.push(rows[i]);
	return out;
}

export function formatMonth(month: string, locale: string) {
	const [year, number] = month.split('-').map(Number);
	return new Intl.DateTimeFormat(locale, {
		month: 'long',
		year: 'numeric',
		timeZone: 'UTC'
	}).format(new Date(Date.UTC(year, number - 1, 1)));
}

// Local capture times have no zone, so they are formatted as UTC to show the same wall clock.
export function localDate(localAt: string) {
	return new Date(`${localAt}Z`);
}

export function formatDay(localAt: string, locale: string) {
	return new Intl.DateTimeFormat(locale, {
		weekday: 'short',
		day: 'numeric',
		month: 'long',
		timeZone: 'UTC'
	}).format(localDate(localAt));
}

export function formatDateTime(localAt: string, locale: string) {
	return new Intl.DateTimeFormat(locale, {
		dateStyle: 'long',
		timeStyle: 'short',
		timeZone: 'UTC'
	}).format(localDate(localAt));
}

export function formatDuration(ms: number) {
	const total = Math.round(ms / 1000);
	const hours = Math.floor(total / 3600);
	const minutes = Math.floor((total % 3600) / 60);
	const seconds = String(total % 60).padStart(2, '0');
	return hours > 0
		? `${hours}:${String(minutes).padStart(2, '0')}:${seconds}`
		: `${minutes}:${seconds}`;
}

/** The month's name on its own, as a title says it, and its year. */
export function monthParts(month: string, locale: string) {
	const [year, number] = month.split('-').map(Number);
	const name = new Intl.DateTimeFormat(locale, { month: 'long', timeZone: 'UTC' }).format(
		new Date(Date.UTC(year, number - 1, 1))
	);
	return { name: name.charAt(0).toLocaleUpperCase(locale) + name.slice(1), year: String(year) };
}

/** How many photos and videos, in words: Croatian has three forms of the noun. */
export function itemCount(count: number, lang: string) {
	if (lang !== 'hr') return `${count} ${count === 1 ? 'item' : 'items'}`;
	const tens = count % 100;
	const ones = count % 10;
	if (ones === 1 && tens !== 11) return `${count} stavka`;
	if (ones >= 2 && ones <= 4 && (tens < 12 || tens > 14)) return `${count} stavke`;
	return `${count} stavki`;
}
