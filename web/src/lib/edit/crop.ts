export type Crop = { x: number; y: number; width: number; height: number };
export type Corner = 'tl' | 'tr' | 'bl' | 'br';

export const wholePicture: Crop = { x: 0, y: 0, width: 1, height: 1 };

const MIN_SIDE = 0.05;
const clamp = (value: number, low: number, high: number) => Math.min(high, Math.max(low, value));

/** Moves one corner, keeping the box inside the picture and from turning inside out. */
export function moveCrop(crop: Crop, corner: Corner, x: number, y: number): Crop {
	let left = crop.x;
	let top = crop.y;
	let right = crop.x + crop.width;
	let bottom = crop.y + crop.height;
	if (corner === 'tl' || corner === 'bl') left = clamp(x, 0, right - MIN_SIDE);
	else right = clamp(x, left + MIN_SIDE, 1);
	if (corner === 'tl' || corner === 'tr') top = clamp(y, 0, bottom - MIN_SIDE);
	else bottom = clamp(y, top + MIN_SIDE, 1);
	return { x: left, y: top, width: right - left, height: bottom - top };
}

/** The same part of the picture after it turns 90° clockwise. */
export function turnCrop(crop: Crop): Crop {
	return {
		x: 1 - crop.y - crop.height,
		y: crop.x,
		width: crop.height,
		height: crop.width
	};
}
