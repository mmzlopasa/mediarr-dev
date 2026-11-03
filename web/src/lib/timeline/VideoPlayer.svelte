<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';
	import type { AssetDetail } from '#lib/api.ts';

	let {
		assetId,
		sources,
		sprite,
		poster,
		autoplay = false,
		onFailed
	}: {
		assetId: string;
		/** Adaptive stream, if it is ready, and the direct file. */
		sources: { hls?: string; direct: string };
		sprite?: AssetDetail['sprite'];
		poster?: string;
		autoplay?: boolean;
		onFailed: () => void;
	} = $props();

	let video = $state<HTMLVideoElement>();
	let duration = $state(0);
	let hover = $state<number | null>(null);

	// Safari plays HLS itself. Other browsers do it through hls.js, which is loaded only when needed.
	$effect(() => {
		const element = video;
		if (!element) return;
		const { hls, direct } = sources;
		let stopped = false;
		let player: { destroy(): void } | undefined;

		if (!hls || element.canPlayType('application/vnd.apple.mpegurl')) {
			element.src = hls ?? direct;
		} else {
			import('hls.js').then(({ default: Hls }) => {
				if (stopped) return;
				if (!Hls.isSupported()) {
					element.src = direct;
					return;
				}
				const instance = new Hls();
				player = instance;
				instance.on(Hls.Events.ERROR, (_event, data) => {
					if (data.fatal) {
						instance.destroy();
						element.src = direct;
					}
				});
				instance.loadSource(hls);
				instance.attachMedia(element);
			});
		}
		return () => {
			stopped = true;
			player?.destroy();
			element.removeAttribute('src');
		};
	});

	const frame = $derived.by(() => {
		if (hover === null || !sprite || !duration) return null;
		const index = Math.min(
			sprite.count - 1,
			Math.floor((hover * duration * 1000) / sprite.intervalMs)
		);
		return {
			x: (index % sprite.columns) * (100 / Math.max(1, sprite.columns - 1)),
			y: Math.floor(index / sprite.columns) * (100 / Math.max(1, sprite.rows - 1))
		};
	});

	function at(event: PointerEvent) {
		const box = (event.currentTarget as HTMLElement).getBoundingClientRect();
		return Math.min(1, Math.max(0, (event.clientX - box.left) / box.width));
	}

	function seek(event: PointerEvent) {
		if (video && duration) video.currentTime = at(event) * duration;
	}
</script>

<div class="vp">
	<video
		bind:this={video}
		class="viewer-media"
		controls
		playsinline
		preload="metadata"
		{poster}
		{autoplay}
		onloadedmetadata={() => (duration = video?.duration ?? 0)}
		onerror={() => {
			// A failed stream falls back to the direct file. Only a failed direct file is final.
			if (video?.currentSrc === new URL(sources.direct, location.href).href) onFailed();
			else if (video && !sources.hls) onFailed();
			else if (video) video.src = sources.direct;
		}}
	></video>
	{#if sprite && duration}
		<div
			class="vp-scrub"
			role="slider"
			tabindex="-1"
			aria-label={tr('Pregled videa', 'Video preview')}
			aria-valuemin="0"
			aria-valuemax="100"
			aria-valuenow={Math.round((hover ?? 0) * 100)}
			onpointermove={(event) => (hover = at(event))}
			onpointerleave={() => (hover = null)}
			onpointerdown={seek}
		>
			{#if frame && hover !== null}
				<span
					class="vp-frame"
					style="left:{hover *
						100}%;background-image:url(/api/assets/{assetId}/video/sprite.jpg);background-size:{sprite.columns *
						100}% {sprite.rows * 100}%;background-position:{frame.x}% {frame.y}%"
				></span>
			{/if}
		</div>
	{/if}
</div>
