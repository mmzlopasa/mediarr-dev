export const languages = { hr: 'Hrvatski', en: 'English' } as const;
export type Lang = keyof typeof languages;

const KEY = 'mediarr_lang';

export function parseLang(stored: string | null, browser: string | undefined): Lang {
	if (stored === 'hr' || stored === 'en') return stored;
	return browser?.toLowerCase().startsWith('hr') ? 'hr' : 'en';
}

function initial(): Lang {
	if (typeof localStorage === 'undefined') return 'hr';
	try {
		return parseLang(localStorage.getItem(KEY), navigator.language);
	} catch {
		return parseLang(null, navigator.language);
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
