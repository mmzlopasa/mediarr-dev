<script lang="ts">
	import { onMount } from 'svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	/** A 360° panorama, turned with a finger or the mouse. The viewer loads only when one opens. */
	let { src, alt }: { src: string; alt: string } = $props();

	let host = $state<HTMLDivElement>();
	let failed = $state(false);

	onMount(() => {
		let viewer: { destroy: () => void } | undefined;
		let gone = false;
		(async () => {
			try {
				const [{ Viewer }] = await Promise.all([
					import('@photo-sphere-viewer/core'),
					import('@photo-sphere-viewer/core/index.css')
				]);
				if (gone || !host) return;
				viewer = new Viewer({
					container: host,
					panorama: src,
					navbar: false,
					loadingTxt: '',
					mousewheelCtrlKey: false,
					touchmoveTwoFingers: false,
					defaultZoomLvl: 30
				});
			} catch {
				failed = true;
			}
		})();
		return () => {
			gone = true;
			viewer?.destroy();
		};
	});
</script>

<!-- The viewer's own gestures turn the panorama; the photo viewer's swipe and zoom stay out. -->
<div
	class="viewer-pano"
	bind:this={host}
	role="img"
	aria-label={tr(`360° panorama: ${alt}`, `360° panorama: ${alt}`)}
	onpointerdown={(event) => event.stopPropagation()}
	onwheel={(event) => event.stopPropagation()}
	ontouchstart={(event) => event.stopPropagation()}
>
	{#if failed}
		<p class="viewer-pano-msg">
			{tr('Panorama se ne može prikazati.', 'The panorama cannot be shown.')}
		</p>
	{/if}
</div>
