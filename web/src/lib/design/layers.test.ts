import { describe, expect, it } from 'vitest';
import { anyLayerOpen, openLayer } from './layers.ts';

describe('layers', () => {
	it('gives keys only to the overlay on top', () => {
		expect(anyLayerOpen()).toBe(false);
		const viewer = openLayer();
		expect(viewer.isTop()).toBe(true);
		const slideshow = openLayer();
		expect(viewer.isTop()).toBe(false);
		expect(slideshow.isTop()).toBe(true);
		slideshow.close();
		expect(viewer.isTop()).toBe(true);
		viewer.close();
		expect(anyLayerOpen()).toBe(false);
	});

	it('lets an overlay under another close without taking the top', () => {
		const below = openLayer();
		const above = openLayer();
		below.close();
		expect(above.isTop()).toBe(true);
		above.close();
		expect(anyLayerOpen()).toBe(false);
	});
});
