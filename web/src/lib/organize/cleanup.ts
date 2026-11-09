import { t } from '#lib/i18n.svelte.ts';
import type { CleanupCategoryId, CleanupItem } from '#lib/api.ts';

export const CATEGORIES: CleanupCategoryId[] = ['blurry', 'screenshots', 'largeVideos', 'bursts'];
export const VIDEO_SIZES = [250, 500, 1000, 2000] as const;

/** Favorites and photos in albums are shown, but not ticked: someone chose them once. */
export const ticked = (item: CleanupItem) => !item.favorite && !item.inAlbum;

export function titleOf(category: CleanupCategoryId): string {
	switch (category) {
		case 'blurry':
			return t('cleanup.blurryPhotos');
		case 'screenshots':
			return t('cleanup.screenshots');
		case 'largeVideos':
			return t('cleanup.largeVideos');
		case 'bursts':
			return t('cleanup.bursts');
	}
}

export function hintOf(category: CleanupCategoryId): string {
	switch (category) {
		case 'blurry':
			return t('cleanup.photosWithVeryFewSharp');
		case 'screenshots':
			return t('cleanup.foundByTheirNameAn');
		case 'largeVideos':
			return t('cleanup.theLargestFirst');
		case 'bursts':
			return t('cleanup.theOtherShotsOfA');
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
