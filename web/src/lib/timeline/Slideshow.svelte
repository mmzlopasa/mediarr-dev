<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { api } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import PlayOnTv from '#lib/cast/PlayOnTv.svelte';
	import CastBar from '#lib/cast/CastBar.svelte';
	import { dateLocale, t, k, type Key } from '#lib/i18n.svelte.ts';
	import { formatDay } from './layout.ts';
	import {
		loadSettings,
		nextIndex,
		PACES,
		playOrder,
		saveSettings,
		shownTransition,
		TRANSITIONS,
		type SlideItem,
		type SlideshowSettings,
		type Transition
	} from './slideshow.ts';

	/** The photos of a list one after another, full screen, from the one that was open. */
	let {
		items,
		startId,
		base = '/api',
		onClose
	}: {
		items: SlideItem[];
		startId: string;
		base?: string;
		onClose: (lastId: string) => void;
	} = $props();

	const HIDE_MS = 3000;
	const browser = typeof window !== 'undefined';

	let settings = $state<SlideshowSettings>(loadSettings(browser ? localStorage : undefined));
	let order = $state<SlideItem[]>(untrack(() => playOrder(items, startId, settings.shuffle)));
	let index = $state(0);
	let previous = $state<SlideItem>();
	let paused = $state(false);
	let controls = $state(true);
	let choosing = $state(false);
	let caption = $state('');
	let ended = $state(false);
	let root = $state<HTMLDivElement>();

	let reduceMotion = $state(false);
	const slide = $derived(order[index]);
	const transition = $derived(shownTransition(settings.transition, reduceMotion));

	let timer: ReturnType<typeof setTimeout> | undefined;
	let hide: ReturnType<typeof setTimeout> | undefined;
	let lock: { release: () => Promise<void> } | undefined;

	const imageUrl = (id: string) => `${base}/assets/${id}/thumbnail?size=large`;

	function go(step: number) {
		const next = nextIndex(index, order.length, settings.loop, step);
		if (next === undefined) {
			ended = true;
			paused = true;
			return;
		}
		ended = false;
		previous = slide;
		index = next;
	}

	// Each photo stays for the chosen time; a video plays to its end instead.
	$effect(() => {
		const current = slide;
		const seconds = settings.seconds;
		clearTimeout(timer);
		if (!current || paused || current.kind === 'video') return;
		timer = setTimeout(() => go(1), seconds * 1000);
		return () => clearTimeout(timer);
	});

	// The next photo is fetched before it is needed, so nothing flashes.
	$effect(() => {
		const next = nextIndex(index, order.length, settings.loop);
		const upcoming = next === undefined ? undefined : order[next];
		if (upcoming && upcoming.kind !== 'video') new Image().src = imageUrl(upcoming.id);
	});

	$effect(() => {
		const current = slide;
		caption = '';
		if (!settings.caption || !current || base !== '/api') return;
		let stale = false;
		api
			.asset(current.id)
			.then((detail) => {
				if (stale) return;
				const place = [detail.city, detail.country].filter(Boolean).join(', ');
				const day = detail.localAt ? formatDay(detail.localAt, dateLocale()) : '';
				caption = [day, place].filter(Boolean).join(' · ');
			})
			.catch(() => undefined);
		return () => {
			stale = true;
		};
	});

	$effect(() => {
		saveSettings(browser ? localStorage : undefined, $state.snapshot(settings));
	});

	function setShuffle(on: boolean) {
		const current = slide?.id ?? startId;
		settings.shuffle = on;
		order = playOrder(items, current, on);
		index = 0;
	}

	function wake() {
		controls = true;
		clearTimeout(hide);
		hide = setTimeout(() => {
			if (!choosing) controls = false;
		}, HIDE_MS);
	}

	let closed = false;

	function close() {
		if (closed) return;
		closed = true;
		if (document.fullscreenElement) document.exitFullscreen().catch(() => undefined);
		onClose(slide?.id ?? startId);
	}

	function toggleFullscreen() {
		if (document.fullscreenElement) document.exitFullscreen().catch(() => undefined);
		else root?.requestFullscreen?.().catch(() => undefined);
	}

	function key(event: KeyboardEvent) {
		if (event.key === 'Escape') close();
		else if (event.key === ' ') {
			event.preventDefault();
			paused = !paused;
		} else if (event.key === 'ArrowRight') go(1);
		else if (event.key === 'ArrowLeft') go(-1);
		else if (event.key === 'f') toggleFullscreen();
		else return;
		wake();
	}

	let touchX = 0;

	async function keepAwake() {
		try {
			const wakeLock = (
				navigator as Navigator & {
					wakeLock?: { request: (type: 'screen') => Promise<{ release: () => Promise<void> }> };
				}
			).wakeLock;
			lock = await wakeLock?.request('screen');
		} catch {
			// The screen may sleep; the slideshow goes on.
		}
	}

	onMount(() => {
		const query = window.matchMedia('(prefers-reduced-motion: reduce)');
		reduceMotion = query.matches;
		const motion = (event: MediaQueryListEvent) => (reduceMotion = event.matches);
		query.addEventListener('change', motion);
		root?.focus();
		root?.requestFullscreen?.().catch(() => undefined);
		keepAwake();
		// The lock goes when the tab is hidden; it is asked for again on coming back.
		const visible = () => {
			if (document.visibilityState === 'visible') keepAwake();
		};
		document.addEventListener('visibilitychange', visible);
		// Leaving full screen, as Esc does in a browser, ends the slideshow too.
		let wasFull = false;
		const fullscreen = () => {
			if (document.fullscreenElement) wasFull = true;
			else if (wasFull) close();
		};
		document.addEventListener('fullscreenchange', fullscreen);
		wake();
		return () => {
			query.removeEventListener('change', motion);
			document.removeEventListener('visibilitychange', visible);
			document.removeEventListener('fullscreenchange', fullscreen);
			clearTimeout(timer);
			clearTimeout(hide);
			lock?.release().catch(() => undefined);
		};
	});

	const transitionNames: Record<Transition, Key> = {
		fade: k('slideshow.transition.fade'),
		slide: k('slideshow.transition.slide'),
		zoom: k('slideshow.transition.zoom'),
		none: k('slideshow.transition.none')
	};
</script>

<div
	class="ss"
	class:ss-idle={!controls}
	bind:this={root}
	role="dialog"
	aria-modal="true"
	aria-label={t('common.slideshow')}
	tabindex="-1"
	onkeydown={key}
	onpointermove={wake}
	onpointerdown={wake}
	ontouchstart={(event) => (touchX = event.touches[0]?.clientX ?? 0)}
	ontouchend={(event) => {
		const dx = (event.changedTouches[0]?.clientX ?? 0) - touchX;
		if (Math.abs(dx) > 50) go(dx < 0 ? 1 : -1);
	}}
	style="--ss-seconds:{settings.seconds}s"
>
	{#if previous && previous.kind !== 'video' && transition !== 'none'}
		<img class="ss-media ss-under" src={imageUrl(previous.id)} alt="" draggable="false" />
	{/if}
	{#if slide}
		{#key slide.id}
			{#if slide.kind === 'video'}
				<video
					class="ss-media ss-in ss-{transition}"
					src="{base}/assets/{slide.id}/original"
					autoplay
					muted
					playsinline
					onended={() => !paused && go(1)}
					onerror={() => !paused && go(1)}
				></video>
			{:else}
				<img
					class="ss-media ss-in ss-{transition}"
					class:ss-still={paused}
					src={imageUrl(slide.id)}
					alt=""
					draggable="false"
				/>
			{/if}
		{/key}
	{/if}

	{#if settings.caption && caption}
		<p class="ss-caption">{caption}</p>
	{/if}
	{#if ended}
		<p class="ss-end" role="status">{t('slideshow.theEnd')}</p>
	{/if}

	<div class="ss-bar" aria-hidden={!controls}>
		<span class="ss-count">{index + 1} / {order.length}</span>
		<div class="ss-buttons">
			<button
				type="button"
				class="icon-btn"
				aria-label={t('slideshow.previous')}
				onclick={() => go(-1)}><Icon name="back" /></button
			>
			<button
				type="button"
				class="icon-btn ss-play"
				aria-label={paused ? t('slideshow.play') : t('slideshow.pause')}
				onclick={() => {
					if (ended) {
						index = 0;
						ended = false;
					}
					paused = !paused;
				}}
			>
				{#if paused}<Icon name="play" />{:else}<svg
						viewBox="0 0 24 24"
						width="18"
						height="18"
						aria-hidden="true"
						><path d="M7 5h3.5v14H7zM13.5 5H17v14h-3.5z" fill="currentColor" /></svg
					>{/if}
			</button>
			<button type="button" class="icon-btn" aria-label={t('slideshow.next')} onclick={() => go(1)}
				><Icon name="forward" /></button
			>
		</div>
		<div class="ss-buttons">
			{#if base === '/api' && slide}
				<PlayOnTv
					id={slide.id}
					kind={slide.kind === 'video' ? 'video' : 'photo'}
					video={() => root?.querySelector('video')}
				/>
			{/if}
			<button
				type="button"
				class="icon-btn"
				class:viewer-on={choosing}
				aria-expanded={choosing}
				aria-label={t('slideshow.slideshowSettings')}
				onclick={() => (choosing = !choosing)}><Icon name="cog" /></button
			>
			<button type="button" class="icon-btn" aria-label={t('common.close')} onclick={close}
				><Icon name="x" /></button
			>
		</div>
	</div>

	<CastBar />

	{#if choosing}
		<form class="ss-settings" aria-label={t('slideshow.slideshowSettings')}>
			<label
				><span>{t('slideshow.pace')}</span>
				<select class="in" bind:value={settings.seconds}>
					{#each PACES as seconds (seconds)}
						<option value={seconds}>{seconds} s</option>
					{/each}
				</select>
			</label>
			<label
				><span>{t('slideshow.transition')}</span>
				<select class="in" bind:value={settings.transition}>
					{#each TRANSITIONS as name (name)}
						<option value={name}>{t(transitionNames[name])}</option>
					{/each}
				</select>
			</label>
			<label class="ss-check"
				><input
					type="checkbox"
					checked={settings.shuffle}
					onchange={(event) => setShuffle(event.currentTarget.checked)}
				/>{t('slideshow.shuffle')}</label
			>
			<label class="ss-check"
				><input type="checkbox" bind:checked={settings.loop} />{t('slideshow.loop')}</label
			>
			<label class="ss-check"
				><input type="checkbox" bind:checked={settings.caption} />{t(
					'slideshow.dateAndPlace'
				)}</label
			>
			{#if reduceMotion}
				<p class="ss-note">
					{t('slideshow.theSystemAsksForLess')}
				</p>
			{/if}
		</form>
	{/if}
</div>
