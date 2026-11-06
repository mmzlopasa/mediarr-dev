<script lang="ts">
	import { onMount } from 'svelte';
	import { reduced } from './motion.ts';
	import { DOT_GRID_DEFAULTS, startDotGrid } from './reactbits/dotGrid.js';

	/*
	 * A quiet field of dots that leans away from the pointer and lights in the accent near it.
	 * From React Bits "DotGrid" (see reactbits/dotGrid.js). Colours come from the theme.
	 */
	let { gap = 22, size = 3 }: { gap?: number; size?: number } = $props();

	let canvas = $state<HTMLCanvasElement>();

	onMount(() => {
		if (!canvas) return;
		const css = getComputedStyle(document.documentElement);
		const read = (name: string, fallback: string) => css.getPropertyValue(name).trim() || fallback;
		const settings = {
			current: {
				...DOT_GRID_DEFAULTS,
				dotSize: size,
				gap,
				baseColor: read('--line-2', '#323846'),
				activeColor: read('--acc', '#c4bbff'),
				proximity: 130,
				strength: 0.8,
				glow: 0.35,
				fade: 0.2,
				clickShock: !reduced(),
				intro: !reduced(),
				mouseInteraction: !reduced()
			}
		};
		const engine = startDotGrid(canvas, settings);
		// The theme can change while the page is open.
		const watch = new MutationObserver(() => {
			const now = getComputedStyle(document.documentElement);
			settings.current.baseColor = now.getPropertyValue('--line-2').trim();
			settings.current.activeColor = now.getPropertyValue('--acc').trim();
			engine.refresh();
		});
		watch.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
		return () => {
			watch.disconnect();
			engine.destroy();
		};
	});
</script>

<div class="dot-grid" aria-hidden="true"><canvas bind:this={canvas}></canvas></div>

<style>
	.dot-grid {
		position: absolute;
		inset: 0;
		pointer-events: none;
	}
	canvas {
		position: absolute;
		inset: 0;
		display: block;
		width: 100%;
		height: 100%;
	}
</style>
