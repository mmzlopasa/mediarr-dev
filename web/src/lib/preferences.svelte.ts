import { api, type UserPreferences } from '#lib/api.ts';

let current = $state<UserPreferences | undefined>();
// How long the trash keeps a photo: only what the server says, never a guess.
let days = $state<number | undefined>();
let daysLoading = $state(true);

/** How long the trash keeps a photo on this server; undefined until the server has said. */
export function trashDays() {
	return days;
}

/** Whether the server has not answered yet about how long the trash keeps photos. */
export function trashDaysLoading() {
	return daysLoading;
}

/** What this person chose, once it has been read from the server. */
export function preferences() {
	return current;
}

export async function loadPreferences() {
	// Each on its own: one failing must not keep the other from showing.
	const [mine, status] = await Promise.allSettled([api.myPreferences(), api.serverStatus()]);
	if (mine.status === 'fulfilled') current = mine.value;
	if (status.status === 'fulfilled') days = status.value.trashDays;
	daysLoading = false;
}

export async function savePreferences(next: UserPreferences) {
	current = await api.setMyPreferences(next);
}
