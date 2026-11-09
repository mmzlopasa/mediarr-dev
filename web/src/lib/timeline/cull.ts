/** A photo's verdict while going through a shoot: 1 picked, -1 rejected, 0 none. */
export type Mark = { pick: number; rating: number };

export const COMPARE_MAX = 4;
export const CHUNK = 1000;

export type CullAction =
	| { type: 'pick'; value: number }
	| { type: 'rate'; value: number }
	| { type: 'move'; by: number }
	| { type: 'zoom' }
	| { type: 'compare' };

/** What a key does; nothing for the keys that are not part of it. */
export function keyAction(key: string): CullAction | undefined {
	switch (key.toLowerCase()) {
		case 'p':
			return { type: 'pick', value: 1 };
		case 'x':
			return { type: 'pick', value: -1 };
		case 'u':
			return { type: 'pick', value: 0 };
		case 'arrowleft':
			return { type: 'move', by: -1 };
		case 'arrowright':
			return { type: 'move', by: 1 };
		case 'z':
			return { type: 'zoom' };
		case 'c':
			return { type: 'compare' };
	}
	return /^[0-5]$/.test(key) ? { type: 'rate', value: Number(key) } : undefined;
}

/** The photos to have ready: three ahead, one behind, the nearest first. */
export function preloadIds(ids: string[], index: number, ahead = 3, behind = 1): string[] {
	const out: string[] = [];
	for (let step = 1; step <= ahead; step++) if (ids[index + step]) out.push(ids[index + step]);
	for (let step = 1; step <= behind; step++) if (ids[index - step]) out.push(ids[index - step]);
	return out;
}

/** A list cut in the pieces one request can take. */
export function chunks<T>(list: T[], size = CHUNK): T[][] {
	const out: T[][] = [];
	for (let at = 0; at < list.length; at += size) out.push(list.slice(at, at + size));
	return out;
}

/** The photos compared after this one is added or taken out; a full list takes no more. */
export function toggleCompared(compared: string[], id: string): string[] {
	if (compared.includes(id)) return compared.filter((entry) => entry !== id);
	return compared.length >= COMPARE_MAX ? compared : [...compared, id];
}

/** The ids with a mark, in their order. */
export function withPick(ids: string[], marks: Record<string, Mark>, pick: number): string[] {
	return ids.filter((id) => marks[id]?.pick === pick);
}

/** How much a photo of these pixels is enlarged to show one of them on one of the screen's. */
export function actualSizeScale(
	photo: { width?: number | null; height?: number | null },
	box: { width: number; height: number }
): number {
	if (!photo.width || !photo.height || !box.width || !box.height) return 2;
	return Math.max(1, Math.max(photo.width / box.width, photo.height / box.height));
}
