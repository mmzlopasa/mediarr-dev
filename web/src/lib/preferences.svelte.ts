import { api, type UserPreferences } from '#lib/api.ts';

let current = $state<UserPreferences | undefined>();
let days = $state(30);

/** How long the trash keeps a photo on this server. */
export function trashDays() {
	return days;
}

/** What this person chose, once it has been read from the server. */
export function preferences() {
	return current;
}

export async function loadPreferences() {
	try {
		const [mine, status] = await Promise.all([api.myPreferences(), api.serverStatus()]);
		current = mine;
		days = status.trashDays;
	} catch {
		// Everything keeps working with its default until the server answers.
	}
}

export async function savePreferences(next: UserPreferences) {
	current = await api.setMyPreferences(next);
}
