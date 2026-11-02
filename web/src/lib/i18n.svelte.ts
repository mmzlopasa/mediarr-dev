export const languages = { en: 'English', hr: 'Hrvatski' } as const;
export type Lang = keyof typeof languages;

const KEY = 'mediarr_lang';

/** English is the main language; other languages apply only when chosen in the menu. */
export function parseLang(stored: string | null): Lang {
	return stored === 'hr' ? 'hr' : 'en';
}

function initial(): Lang {
	if (typeof localStorage === 'undefined') return 'en';
	try {
		return parseLang(localStorage.getItem(KEY));
	} catch {
		return 'en';
	}
}

let current = $state<Lang>(initial());

export function lang() {
	return current;
}

export function setLang(next: Lang) {
	current = next;
	document.documentElement.lang = next;
	try {
		localStorage.setItem(KEY, next);
	} catch {
		// Storage can be blocked; the language still applies to this page.
	}
}

/** Picks the text for the current language. */
export function tr(hr: string, en: string) {
	return current === 'hr' ? hr : en;
}
