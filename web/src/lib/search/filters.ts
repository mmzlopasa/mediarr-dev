import { t } from '#lib/i18n.svelte.ts';
import type { SearchResult } from '#lib/api.ts';

type Filters = SearchResult['filters'];

/** Every address parameter of a search that narrows it. */
export const FILTER_KEYS = [
	'from',
	'to',
	'person',
	'people',
	'place',
	'camera',
	'lens',
	'type',
	'minRating',
	'tag',
	'album',
	'notInAlbum',
	'favorite'
] as const;

/** Whether there is anything to search for: words, or a filter. */
export function hasSearch(params: URLSearchParams): boolean {
	return Boolean(params.get('q')?.trim()) || FILTER_KEYS.some((key) => params.has(key));
}

export type Chip = {
	/** What it removes: a parameter, with the value for those that repeat. */
	key: string;
	value?: string;
	label: string;
	/** Found in the words, not chosen; removing it searches the word as a word. */
	found: boolean;
};

/** The filters a search used, as chips, marked by whether they were chosen or found in the words. */
export function chipsFor(
	filters: Filters,
	params: URLSearchParams,
	day: (iso: string) => string
): Chip[] {
	const chips: Chip[] = [];
	const chosen = (key: string, value?: string) =>
		value === undefined ? params.has(key) : params.getAll(key).includes(value);
	if (filters.from || filters.to) {
		const label = `${filters.from ? day(filters.from) : '…'} – ${filters.to ? day(filters.to) : '…'}`;
		chips.push({ key: 'dates', label, found: !params.has('from') && !params.has('to') });
	}
	for (const person of filters.people ?? []) {
		chips.push({
			key: 'person',
			value: person.id,
			label: person.name || t('common.noName'),
			found: !chosen('person', person.id)
		});
	}
	if ((filters.people?.length ?? 0) > 1 && filters.peopleMatch === 'any') {
		chips.push({ key: 'people', label: t('filters.anyOfThem'), found: false });
	}
	for (const [key, value] of [
		['place', filters.place],
		['camera', filters.camera],
		['lens', filters.lens]
	] as const) {
		if (value) chips.push({ key, label: value, found: !chosen(key) });
	}
	if (filters.type) {
		chips.push({
			key: 'type',
			label: filters.type === 'video' ? t('common.videos') : t('common.photos'),
			found: false
		});
	}
	if (filters.minRating)
		chips.push({ key: 'minRating', label: `${'★'.repeat(filters.minRating)}+`, found: false });
	for (const tag of filters.tags ?? [])
		chips.push({ key: 'tag', value: tag, label: `#${tag}`, found: false });
	if (filters.album)
		chips.push({
			key: 'album',
			label: t('filters.inAlbumTitle', { title: filters.album.title }),
			found: false
		});
	if (filters.notInAlbum)
		chips.push({ key: 'notInAlbum', label: t('filters.inNoAlbum'), found: false });
	if (filters.favorite)
		chips.push({ key: 'favorite', label: t('filters.favourites'), found: false });
	return chips;
}

/**
 * The search without one chip. A chosen filter is simply dropped. A filter found in the words is
 * dropped by searching the words as they are, keeping the other filters found in them as chosen ones.
 */
export function withoutChip(
	params: URLSearchParams,
	chip: Chip,
	filters: Filters
): URLSearchParams {
	const next = new URLSearchParams(params);
	const drop = (key: string, value?: string) => {
		if (value === undefined) {
			next.delete(key);
			return;
		}
		const kept = next.getAll(key).filter((entry) => entry !== value);
		next.delete(key);
		for (const entry of kept) next.append(key, entry);
	};
	if (chip.found) {
		next.set('plain', 'true');
		if (chip.key !== 'dates' && (filters.from || filters.to)) {
			if (filters.from) next.set('from', filters.from);
			if (filters.to) next.set('to', filters.to);
		}
		for (const person of filters.people ?? []) {
			if (
				!(chip.key === 'person' && chip.value === person.id) &&
				!next.getAll('person').includes(person.id)
			) {
				next.append('person', person.id);
			}
		}
		for (const key of ['place', 'camera', 'lens'] as const) {
			if (chip.key !== key && filters[key] && !next.has(key)) next.set(key, filters[key] as string);
		}
		return next;
	}
	if (chip.key === 'dates') {
		drop('from');
		drop('to');
	} else {
		drop(chip.key, chip.value);
	}
	if (next.getAll('person').length < 2) next.delete('people');
	return next;
}
