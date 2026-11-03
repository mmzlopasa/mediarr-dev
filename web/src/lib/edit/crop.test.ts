import { describe, expect, it } from 'vitest';
import { moveCrop, turnCrop, wholePicture } from './crop.ts';

describe('crop', () => {
	it('moves one corner and stays inside the picture', () => {
		expect(moveCrop(wholePicture, 'tl', 0.25, 0.5)).toEqual({
			x: 0.25,
			y: 0.5,
			width: 0.75,
			height: 0.5
		});
		expect(moveCrop(wholePicture, 'br', 2, -1).height).toBeCloseTo(0.05);
	});

	it('never turns inside out', () => {
		const crop = moveCrop(wholePicture, 'tl', 5, 5);
		expect(crop.width).toBeCloseTo(0.05);
		expect(crop.x + crop.width).toBeCloseTo(1);
	});

	it('follows the picture when it turns', () => {
		// The left half of the picture is its top half after turning clockwise.
		const left = { x: 0, y: 0, width: 0.5, height: 1 };
		expect(turnCrop(left)).toEqual({ x: 0, y: 0, width: 1, height: 0.5 });
		expect(turnCrop(turnCrop(turnCrop(turnCrop(left))))).toEqual(left);
	});
});
