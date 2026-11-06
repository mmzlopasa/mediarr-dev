const KEY = 'mediarr_theme';

function apply(pref: string | null) {
	const theme =
		pref === 'light' || pref === 'dark'
			? pref
			: matchMedia('(prefers-color-scheme: light)').matches
				? 'light'
				: 'dark';
	document.documentElement.dataset.theme = theme;
}

export function toggleTheme() {
	const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
	try {
		localStorage.setItem(KEY, next);
	} catch {
		// Storage can be blocked; the theme still applies to this page.
	}
	apply(next);
}

function storedTheme() {
	try {
		return localStorage.getItem(KEY);
	} catch {
		return null;
	}
}

/** Follows the system theme while no choice is stored, and other tabs. Returns a cleanup function. */
export function watchTheme() {
	const media = matchMedia('(prefers-color-scheme: light)');
	const onMedia = () => {
		if (!storedTheme()) apply(null);
	};
	const onStorage = (e: StorageEvent) => {
		if (e.key === KEY) apply(e.newValue);
	};
	media.addEventListener('change', onMedia);
	addEventListener('storage', onStorage);
	return () => {
		media.removeEventListener('change', onMedia);
		removeEventListener('storage', onStorage);
	};
}

export type ThemeChoice = 'dark' | 'light' | 'system';

/** What the person chose: a fixed theme, or whatever the system shows. */
export function themeChoice(): ThemeChoice {
	const stored = storedTheme();
	return stored === 'light' || stored === 'dark' ? stored : 'system';
}

export function setTheme(choice: ThemeChoice) {
	try {
		if (choice === 'system') localStorage.removeItem(KEY);
		else localStorage.setItem(KEY, choice);
	} catch {
		// Storage can be blocked; the theme still applies to this page.
	}
	apply(choice === 'system' ? null : choice);
}
