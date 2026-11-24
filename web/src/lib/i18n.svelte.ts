import en from './i18n/en.json';

/** Every text has a key; English is the source and what is shown when a translation is missing. */
export type Key = keyof typeof en;
type Catalog = Partial<Record<Key, string>>;
export type Params = Record<string, string | number | undefined>;

/** Each in its own words; a machine translation says so until a person has read it. */
export const languages = {
	en: 'English',
	hr: 'Hrvatski',
	de: 'Deutsch (maschinell übersetzt)',
	sl: 'Slovenščina (strojni prevod)'
} as const;
export type Lang = keyof typeof languages;

/** Machine translated, not yet read by a person who speaks the language. */
export const unreviewed: readonly Lang[] = ['de', 'sl'];

const KEY = 'mediarr_lang';

// English comes with the page; another language is fetched only when it is chosen, so nobody loads
// the words of all of them. If one cannot be fetched the page stays in English, which always works.
const catalogs: Record<Exclude<Lang, 'en'>, () => Promise<{ default: Catalog }>> = {
	hr: () => import('./i18n/hr.json'),
	de: () => import('./i18n/de.json'),
	sl: () => import('./i18n/sl.json')
};
// Not state: what has been fetched, kept so that switching back costs nothing.
const fetched: Partial<Record<Lang, Catalog>> = { en: {} };

async function fetchCatalog(language: Lang): Promise<Catalog | undefined> {
	if (language === 'en') return fetched.en;
	try {
		fetched[language] ??= (await catalogs[language]()).default;
	} catch {
		// A failed fetch is tried again the next time the language is chosen.
	}
	return fetched[language];
}

/** English is the main language; other languages apply only when chosen. */
export function parseLang(stored: string | null | undefined): Lang {
	return stored && stored in languages ? (stored as Lang) : 'en';
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
// The words of the language they were fetched for; until then English is shown.
let catalog = $state<{ lang: Lang; words: Catalog }>({ lang: 'en', words: {} });

export function lang() {
	return current;
}

// How each language writes dates and numbers; English is written the British way.
const LOCALES: Record<Lang, string> = { en: 'en-GB', hr: 'hr-HR', de: 'de-DE', sl: 'sl-SI' };

/** The locale for dates and numbers in the chosen language. */
export function dateLocale() {
	return LOCALES[current];
}

/** Fetches the texts of a language and shows them, if it is still the chosen one by then. */
export async function loadLang(next: Lang = current) {
	const words = await fetchCatalog(next);
	if (words && next === current) catalog = { lang: next, words };
}

export async function setLang(next: Lang) {
	// Fetched first, so the page changes language at once and not word by word.
	await fetchCatalog(next);
	current = next;
	if (typeof document !== 'undefined') document.documentElement.lang = next;
	try {
		localStorage.setItem(KEY, next);
	} catch {
		// Storage can be blocked; the language still applies to this page.
	}
	await loadLang(next);
}

// Not state: a cache that nothing shows.
const plurals: Partial<Record<Lang, Intl.PluralRules>> = {};

function pluralOf(language: Lang, count: number) {
	plurals[language] ??= new Intl.PluralRules(language);
	return plurals[language].select(count);
}

/**
 * Fills a text: {name} takes a parameter, and {name, plural, one {…} few {…} other {…}} picks the
 * form for the number, where # is the number itself.
 */
export function format(text: string, params: Params = {}, language: Lang = current): string {
	let out = '';
	let i = 0;
	while (i < text.length) {
		const open = text.indexOf('{', i);
		if (open < 0) {
			out += text.slice(i);
			break;
		}
		out += text.slice(i, open);
		const end = closing(text, open);
		const inner = text.slice(open + 1, end);
		const [name, kind, ...rest] = inner.split(',');
		const value = params[name.trim()];
		if (kind?.trim() === 'plural') {
			const count = Number(value ?? 0);
			const forms = choices(rest.join(','));
			const form = forms[`=${count}`] ?? forms[pluralOf(language, count)] ?? forms.other ?? '';
			out += format(form, params, language).replaceAll('#', number(count, language));
		} else {
			out += value === undefined ? '' : typeof value === 'number' ? number(value, language) : value;
		}
		i = end + 1;
	}
	return out;
}

function number(value: number, language: Lang) {
	return Number.isInteger(value) ? value.toLocaleString(language) : String(value);
}

function closing(text: string, open: number) {
	let depth = 0;
	for (let i = open; i < text.length; i++) {
		if (text[i] === '{') depth++;
		else if (text[i] === '}' && --depth === 0) return i;
	}
	return text.length - 1;
}

function choices(body: string): Record<string, string> {
	const out: Record<string, string> = {};
	let i = 0;
	while (i < body.length) {
		const open = body.indexOf('{', i);
		if (open < 0) break;
		const label = body.slice(i, open).trim();
		const end = closing(body, open);
		out[label] = body.slice(open + 1, end);
		i = end + 1;
	}
	return out;
}

/** The text of a key in the chosen language. */
export function t(key: Key, params?: Params): string {
	const text =
		(current === 'en' || catalog.lang !== current ? undefined : catalog.words[key]) ??
		en[key] ??
		key;
	return params || text.includes('{') ? format(text, params) : text;
}

/** Marks a text kept in data, such as a menu, as a key; it is checked like any other. */
export function k(key: Key): Key {
	return key;
}
