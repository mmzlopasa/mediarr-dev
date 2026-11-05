import type { Memory } from '#lib/api.ts';
import { tr } from '#lib/i18n.svelte.ts';

/** A memory's title in words: the server only says what kind it is and when. */
export function memoryTitle(memory: Memory, thisYear = new Date().getFullYear()) {
	if (memory.kind === 'week') return tr('Protekli tjedan', 'The last week');
	const years = thisYear - (memory.year ?? 0);
	return tr(`Na današnji dan, ${memory.year}.`, `On this day, ${years} years ago`);
}
