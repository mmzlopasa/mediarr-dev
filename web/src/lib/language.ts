import { api } from '#lib/api.ts';
import { lang, parseLang, setLang, type Lang } from '#lib/i18n.svelte.ts';

/** Chooses a language here and, when someone is signed in, for their account on every device. */
export async function chooseLang(next: Lang, signedIn = true) {
	await setLang(next);
	if (signedIn) await api.updateProfile({ language: next }).catch(() => undefined);
}

/**
 * A device that has not chosen a language yet takes the account's, so a new phone or browser starts
 * in it. A device that has chosen keeps its choice and gives it to the account.
 */
export async function followAccount(language: string | undefined) {
	if (!chosenHere()) {
		if (language) await setLang(parseLang(language));
		return;
	}
	if (language !== lang()) await api.updateProfile({ language: lang() }).catch(() => undefined);
}

function chosenHere() {
	try {
		return Boolean(localStorage.getItem('mediarr_lang'));
	} catch {
		return false;
	}
}
