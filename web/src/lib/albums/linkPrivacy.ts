import type { HideFaces, LinkVisit, ShareLink } from '#lib/api.ts';

/** What a link hides and asks, as the form edits it. */
export type PrivacyOptions = {
	showLocation: boolean;
	hideFaces: HideFaces;
	visiblePeople: string[];
	stripCamera: boolean;
	stripDate: boolean;
	askName: boolean;
};

/** A new link: no location and no camera details, as the server does too. */
export function newPrivacy(): PrivacyOptions {
	return {
		showLocation: false,
		hideFaces: 'none',
		visiblePeople: [],
		stripCamera: true,
		stripDate: false,
		askName: false
	};
}

/** The options of a link that exists; anything it does not say is off. */
export function privacyOf(link: ShareLink): PrivacyOptions {
	return {
		showLocation: link.showLocation,
		hideFaces: link.hideFaces ?? 'none',
		visiblePeople: [...(link.visiblePeople ?? [])],
		stripCamera: link.stripCamera ?? false,
		stripDate: link.stripDate ?? false,
		askName: link.askName ?? false
	};
}

/** What is sent: the chosen people only count when everyone else is hidden. */
export function privacyBody(options: PrivacyOptions): PrivacyOptions {
	return {
		...options,
		visiblePeople: options.hideFaces === 'except' ? [...options.visiblePeople] : []
	};
}

/** "Split, Croatia", only the part that is known, or nothing when the place is not known. */
export function placeOf(visit: Pick<LinkVisit, 'city' | 'country'>): string | undefined {
	const parts = [visit.city, visit.country].map((part) => part?.trim()).filter(Boolean);
	return parts.length ? parts.join(', ') : undefined;
}

/** Turns a person on or off in the list of those who stay visible. */
export function togglePerson(people: string[], id: string, on: boolean): string[] {
	const rest = people.filter((person) => person !== id);
	return on ? [...rest, id] : rest;
}
