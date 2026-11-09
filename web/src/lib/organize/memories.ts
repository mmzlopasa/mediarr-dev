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
