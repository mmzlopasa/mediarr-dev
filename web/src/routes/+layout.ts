// The client is a single-page app served as static files by the Go binary.
export const ssr = false;

import { loadLang } from '#lib/i18n.svelte.ts';

// The chosen language is loaded before the first page shows, so it never starts in English.
export async function load() {
	await loadLang();
}
