import de from './i18n/de.json';
import en from './i18n/en.json';
import hr from './i18n/hr.json';
import sl from './i18n/sl.json';

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

// All of them come with the page: loading one later could fail, and a page must never fail over its
// words. Each is about 20 KB compressed.
const catalogs: Record<Exclude<Lang, 'en'>, Catalog> = { hr, de, sl };

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
let catalog = $state<Catalog>(current === 'en' ? {} : catalogs[current]);

export function lang() {
	return current;
}

/** Picks the texts of a language. Kept async for callers that awaited loading. */
export async function loadLang(next: Lang = current) {
	catalog = next === 'en' ? {} : catalogs[next];
}

export async function setLang(next: Lang) {
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
	const text = (current === 'en' ? undefined : catalog[key]) ?? en[key] ?? key;
	return params || text.includes('{') ? format(text, params) : text;
}

/** Marks a text kept in data, such as a menu, as a key; it is checked like any other. */
export function k(key: Key): Key {
	return key;
}
