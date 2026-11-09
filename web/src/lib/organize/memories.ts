import type { Memory } from '#lib/api.ts';
import { t } from '#lib/i18n.svelte.ts';

/** A memory's title in words: the server only says what kind it is and when. */
export function memoryTitle(memory: Memory, thisYear = new Date().getFullYear()) {
	if (memory.kind === 'week') return t('memories.theLastWeek');
	const years = thisYear - (memory.year ?? 0);
	return t('memories.onThisDayYearsYears', { years, year: memory.year });
}
