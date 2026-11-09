import { t } from '#lib/i18n.svelte.ts';
import type { DuplicateGroup } from '#lib/api.ts';

type Item = DuplicateGroup['items'][number];
/**
 * What resolving a group does with the person's ticks: one photo stays and takes over what the
 * others had; the unticked go to the trash. A second ticked photo is left as it is.
 */
export function choiceOf(
	group: DuplicateGroup,
	keeps: (id: string) => boolean
): { keepId: string; trashIds: string[] } | undefined {
	const kept = group.items.filter((item) => keeps(item.id));
	const trashIds = group.items.filter((item) => !keeps(item.id)).map((item) => item.id);
	if (kept.length === 0 || trashIds.length === 0) return undefined;
	const keepId = kept.some((item) => item.id === group.keepId) ? group.keepId : kept[0].id;
	return { keepId, trashIds };
}

/** Short facts about one copy, for telling the copies apart. */
export function notesOf(item: Item): string[] {
	const notes: string[] = [];
	if (item.favorite) notes.push(t('common.favorite'));
	if (item.original) notes.push(t('duplicates.original'));
	if (item.resaved) notes.push(t('duplicates.savedAgainByAnApp'));
	if (item.hasLocation) notes.push(t('duplicates.hasALocation'));
	if (item.hasCaption) notes.push(t('duplicates.hasADescription'));
	if (!item.hasDate) notes.push(t('duplicates.noDate'));
	return notes;
}

/** Why this one is proposed: the first way it is better than the others. */
export function reasonOf(group: DuplicateGroup): string {
	const keep = group.items.find((item) => item.id === group.keepId);
	if (!keep) return '';
	const others = group.items.filter((item) => item !== keep);
	const pixels = (item: Item) => (item.width ?? 0) * (item.height ?? 0);
	if (keep.favorite && others.some((item) => !item.favorite)) return t('duplicates.aFavorite');
	if (keep.original && others.some((item) => !item.original))
		return t('duplicates.theCameraSOriginal');
	if (others.some((item) => item.resaved) && !keep.resaved)
		return t('duplicates.theOthersWereSavedAgain');
	if (others.every((item) => pixels(item) < pixels(keep)))
		return t('duplicates.theHighestResolution');
	if (others.every((item) => item.sizeBytes < keep.sizeBytes))
		return t('duplicates.theLargestFile');
	if (others.every((item) => item.sizeBytes === keep.sizeBytes && pixels(item) === pixels(keep)))
		return t('duplicates.theyAreEqualSoAny');
	return t('duplicates.theSharpest');
}
