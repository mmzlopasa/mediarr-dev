import { decode } from 'blurhash';

const SIZE = 16;
const MAX_CACHED = 2000;
const cache = new Map<string, string>();

/** A small data URL for a blurhash, cached because the same tiles scroll in and out of view. */
export function blurUrl(hash: string | undefined) {
	if (!hash) return undefined;
	const cached = cache.get(hash);
	if (cached) return cached;
	try {
		const pixels = decode(hash, SIZE, SIZE);
		const canvas = document.createElement('canvas');
		canvas.width = SIZE;
		canvas.height = SIZE;
		const context = canvas.getContext('2d');
		if (!context) return undefined;
		const image = context.createImageData(SIZE, SIZE);
		image.data.set(pixels);
		context.putImageData(image, 0, 0);
		const url = canvas.toDataURL();
		if (cache.size >= MAX_CACHED) cache.clear();
		cache.set(hash, url);
		return url;
	} catch {
		return undefined;
	}
}

/**
 * A short mark for a picture's current look. The blurhash changes when an edit makes new previews,
 * so the address changes and every device fetches them, while unchanged ones stay cached.
 */
export function thumbVersion(blurhash?: string | null) {
	if (!blurhash) return '';
	let hash = 0;
	for (let i = 0; i < blurhash.length; i++) hash = (hash * 31 + blurhash.charCodeAt(i)) | 0;
	return (hash >>> 0).toString(36);
}

/** The address of a preview, with its version when it is known. */
export function thumbUrl(base: string, id: string, blurhash?: string | null, size?: string) {
	const query = [size ? `size=${size}` : '', blurhash ? `v=${thumbVersion(blurhash)}` : ''].filter(
		Boolean
	);
	return `${base}/assets/${id}/thumbnail${query.length ? `?${query.join('&')}` : ''}`;
}
