import type { CleanupCategoryId, CleanupItem } from '#lib/api.ts';

type Say = (hr: string, en: string) => string;

export const CATEGORIES: CleanupCategoryId[] = ['blurry', 'screenshots', 'largeVideos', 'bursts'];
export const VIDEO_SIZES = [250, 500, 1000, 2000] as const;

/** Favorites and photos in albums are shown, but not ticked: someone chose them once. */
export const ticked = (item: CleanupItem) => !item.favorite && !item.inAlbum;

export function titleOf(category: CleanupCategoryId, tr: Say): string {
	switch (category) {
		case 'blurry':
			return tr('Mutne fotke', 'Blurry photos');
		case 'screenshots':
			return tr('Screenshotovi', 'Screenshots');
		case 'largeVideos':
			return tr('Veliki videi', 'Large videos');
		case 'bursts':
			return tr('Nizovi', 'Bursts');
	}
}

export function hintOf(category: CleanupCategoryId, tr: Say): string {
	switch (category) {
		case 'blurry':
			return tr(
				'Fotke s vrlo malo oštrih rubova. Klizač određuje koliko strogo.',
				'Photos with very few sharp edges. The slider sets how strict.'
			);
		case 'screenshots':
			return tr(
				'Prepoznati po imenu, oznaci s iPhonea ili obliku ekrana.',
				"Found by their name, an iPhone's mark, or the shape of a screen."
			);
		case 'largeVideos':
			return tr('Najveći prvi.', 'The largest first.');
		case 'bursts':
			return tr(
				'Ostali kadrovi niza. Najbolji kadar ostaje.',
				'The other shots of a burst. The best shot stays.'
			);
	}
}

/** A video's length as m:ss, or h:mm:ss when it is long. */
export function lengthOf(ms: number): string {
	const total = Math.round(ms / 1000);
	const hours = Math.floor(total / 3600);
	const minutes = Math.floor((total % 3600) / 60);
	const seconds = String(total % 60).padStart(2, '0');
	return hours > 0
		? `${hours}:${String(minutes).padStart(2, '0')}:${seconds}`
		: `${minutes}:${seconds}`;
}
