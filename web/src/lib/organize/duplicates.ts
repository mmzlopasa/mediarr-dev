import type { DuplicateGroup } from '#lib/api.ts';

type Item = DuplicateGroup['items'][number];
type Say = (hr: string, en: string) => string;

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
export function notesOf(item: Item, tr: Say): string[] {
	const notes: string[] = [];
	if (item.favorite) notes.push(tr('Favorit', 'Favorite'));
	if (item.original) notes.push(tr('Original', 'Original'));
	if (item.resaved) notes.push(tr('Kopija iz aplikacije', 'Saved again by an app'));
	if (item.hasLocation) notes.push(tr('Ima lokaciju', 'Has a location'));
	if (item.hasCaption) notes.push(tr('Ima opis', 'Has a description'));
	if (!item.hasDate) notes.push(tr('Bez datuma', 'No date'));
	return notes;
}

/** Why this one is proposed: the first way it is better than the others. */
export function reasonOf(group: DuplicateGroup, tr: Say): string {
	const keep = group.items.find((item) => item.id === group.keepId);
	if (!keep) return '';
	const others = group.items.filter((item) => item !== keep);
	const pixels = (item: Item) => (item.width ?? 0) * (item.height ?? 0);
	if (keep.favorite && others.some((item) => !item.favorite)) return tr('favorit', 'a favorite');
	if (keep.original && others.some((item) => !item.original))
		return tr('original iz kamere', "the camera's original");
	if (others.some((item) => item.resaved) && !keep.resaved)
		return tr('ostale su kopije iz aplikacija', 'the others were saved again by apps');
	if (others.every((item) => pixels(item) < pixels(keep)))
		return tr('najveća razlučivost', 'the highest resolution');
	if (others.every((item) => item.sizeBytes < keep.sizeBytes))
		return tr('najveća datoteka', 'the largest file');
	if (others.every((item) => item.sizeBytes === keep.sizeBytes && pixels(item) === pixels(keep)))
		return tr('jednake su, svejedno koja ostaje', 'they are equal, so any one can stay');
	return tr('najoštrija', 'the sharpest');
}
