/** What a slideshow shows, and how. Settings stay on this device. */
export type SlideItem = { id: string; kind?: string; localAt?: string };

export type Transition = 'fade' | 'slide' | 'zoom' | 'none';

export type SlideshowSettings = {
	seconds: number;
	transition: Transition;
	shuffle: boolean;
	loop: boolean;
	caption: boolean;
};

export const PACES = [3, 5, 10, 20] as const;
export const TRANSITIONS: Transition[] = ['fade', 'slide', 'zoom', 'none'];

const KEY = 'mediarr_slideshow';

export const DEFAULT_SETTINGS: SlideshowSettings = {
	seconds: 5,
	transition: 'fade',
	shuffle: false,
	loop: true,
	caption: false
};

/** Reads the settings kept on this device; anything missing or wrong takes its default. */
export function loadSettings(storage: Pick<Storage, 'getItem'> | undefined): SlideshowSettings {
	try {
		const raw = JSON.parse(storage?.getItem(KEY) ?? '{}') as Partial<SlideshowSettings>;
		return {
			seconds: PACES.includes(raw.seconds as (typeof PACES)[number])
				? (raw.seconds as number)
				: DEFAULT_SETTINGS.seconds,
			transition: TRANSITIONS.includes(raw.transition as Transition)
				? (raw.transition as Transition)
				: DEFAULT_SETTINGS.transition,
			shuffle: typeof raw.shuffle === 'boolean' ? raw.shuffle : DEFAULT_SETTINGS.shuffle,
			loop: typeof raw.loop === 'boolean' ? raw.loop : DEFAULT_SETTINGS.loop,
			caption: typeof raw.caption === 'boolean' ? raw.caption : DEFAULT_SETTINGS.caption
		};
	} catch {
		return { ...DEFAULT_SETTINGS };
	}
}

export function saveSettings(
	storage: Pick<Storage, 'setItem'> | undefined,
	settings: SlideshowSettings
) {
	try {
		storage?.setItem(KEY, JSON.stringify(settings));
	} catch {
		// A private window may not keep anything; the slideshow still runs.
	}
}

/**
 * The order the slides go in. It starts with the photo that was open. Shuffled, that one still
 * comes first and the rest follow in a random order.
 */
export function playOrder<T extends SlideItem>(
	items: T[],
	startId: string,
	shuffle: boolean,
	random: () => number = Math.random
): T[] {
	const start = Math.max(
		0,
		items.findIndex((item) => item.id === startId)
	);
	if (!shuffle) return [...items.slice(start), ...items.slice(0, start)];
	const first = items[start];
	const rest = items.filter((_, index) => index !== start);
	for (let i = rest.length - 1; i > 0; i--) {
		const j = Math.floor(random() * (i + 1));
		[rest[i], rest[j]] = [rest[j], rest[i]];
	}
	return first ? [first, ...rest] : rest;
}

/** The next slide, or undefined at the end when it does not go round again. */
export function nextIndex(
	index: number,
	count: number,
	loop: boolean,
	step = 1
): number | undefined {
	if (count === 0) return undefined;
	const next = index + step;
	if (next >= 0 && next < count) return next;
	if (!loop) return undefined;
	return ((next % count) + count) % count;
}

/** Without motion, as the system asks, a slide only fades. */
export function shownTransition(transition: Transition, reduceMotion: boolean): Transition {
	return reduceMotion && (transition === 'slide' || transition === 'zoom') ? 'fade' : transition;
}
