import type { Memory } from '#lib/api.ts';
import { k, t, type Key } from '#lib/i18n.svelte.ts';

const monthNames: Key[] = [
	k('memories.month1'),
	k('memories.month2'),
	k('memories.month3'),
	k('memories.month4'),
	k('memories.month5'),
	k('memories.month6'),
	k('memories.month7'),
	k('memories.month8'),
	k('memories.month9'),
	k('memories.month10'),
	k('memories.month11'),
	k('memories.month12')
];

/** A memory's title in words: the server only says what kind it is and gives the facts. */
export function memoryTitle(memory: Memory, thisYear = new Date().getFullYear()) {
	const params = memory.titleParams ?? {};
	switch (memory.kind) {
		case 'week':
			return t('memories.theLastWeek');
		case 'trip':
			return t('memories.tripTitle', {
				place: params.place ?? '',
				month: params.month ? t(monthNames[params.month - 1]) : '',
				year: String(params.year ?? '')
			});
		case 'person_years':
			return t('memories.personYears', { person: params.person ?? '' });
		case 'birthday':
			return t('memories.birthday', { person: params.person ?? '' });
		case 'year_review':
			return t('memories.yearReview', { year: String(params.year ?? '') });
		case 'month_ago':
			return t('memories.monthAgo');
		default: {
			const years = thisYear - (memory.year ?? 0);
			return t('memories.onThisDayYearsYears', { years, year: memory.year });
		}
	}
}

const ISO_DAY = /^\d{4}-\d{2}-\d{2}$/;

/**
 * When a memory is from, in the reader's language: the server sends a year, a day or a span of days
 * ("2024-07-12 – 2024-07-19"), and this writes it as "12–19 Jul 2024".
 */
export function memoryDates(memory: Memory, locale: string) {
	const days = memory.title.split(/\s*[–/]\s*/);
	if (!days.every((day) => ISO_DAY.test(day))) return memory.title;
	const [from, to] = days.map((day) => new Date(`${day}T12:00:00Z`));
	const format = new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeZone: 'UTC' });
	return to && to.getTime() !== from.getTime() ? format.formatRange(from, to) : format.format(from);
}
