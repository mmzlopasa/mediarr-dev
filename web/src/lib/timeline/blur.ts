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
