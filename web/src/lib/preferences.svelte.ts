import { api, type UserPreferences } from '#lib/api.ts';

let current = $state<UserPreferences | undefined>();

/** What this person chose, once it has been read from the server. */
export function preferences() {
	return current;
}

export async function loadPreferences() {
	try {
		current = await api.myPreferences();
	} catch {
		// Everything keeps working with its default until the server answers.
	}
}

export async function savePreferences(next: UserPreferences) {
	current = await api.setMyPreferences(next);
}
