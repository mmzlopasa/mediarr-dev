<script lang="ts">
	import ShareButton from '#lib/design/components/ShareButton.svelte';
	import { thumbUrl } from './blur.ts';
	import AssetFactsDialog from '#lib/organize/AssetFactsDialog.svelte';
	import RatingStars from '#lib/organize/RatingStars.svelte';
	import FacesEditor from '#lib/organize/FacesEditor.svelte';
	import { preferences, trashDays } from '#lib/preferences.svelte.ts';
	import { onMount, untrack } from 'svelte';
	import { holdScroll } from '#lib/motion/motion.ts';
	import { pulse } from '#lib/motion/actions.ts';
	import { api, formatBytes, type AssetDetail } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, t } from '#lib/i18n.svelte.ts';
	import { formatDateTime, formatDuration } from './layout.ts';
	import PanoramaView from './PanoramaView.svelte';
	import Slideshow from './Slideshow.svelte';
	import type { SlideItem } from './slideshow.ts';
	import VideoPlayer from './VideoPlayer.svelte';
	import AlbumActivity from './AlbumActivity.svelte';
	import PhotoEditor from '#lib/edit/PhotoEditor.svelte';

	const MIN_SCALE = 1;
	const MAX_SCALE = 6;
	const SWIPE_DISTANCE = 60;
	const FULL_PREVIEW_SCALE = 1.5;

	let {
		id,
		onClose,
		onNavigate,
		onChanged,
		base = '/api',
		neighbours,
		strip,
		playlist,
		albumId,
		previewOnly = false
	}: {
		id: string;
		onClose: () => void;
		onNavigate: (id: string) => void;
		onChanged: () => void;
		base?: string;
		neighbours?: (id: string) => { newer?: string; older?: string };
		/** The photos around this one, to show as a strip; the ones that are loaded. */
		strip?: (id: string) => { id: string; blurhash?: string | null }[];
		/** Everything a slideshow from this photo can show; without it, the photos already loaded. */
		playlist?: (id: string) => Promise<SlideItem[]>;
		albumId?: string;
		previewOnly?: boolean;
	} = $props();

	const load = (asset: string) =>
		base === '/api' ? api.asset(asset) : (fetchPublicAsset(asset) as Promise<AssetDetail>);

	async function fetchPublicAsset(asset: string) {
		const response = await fetch(`${base}/assets/${asset}`);
		if (!response.ok) throw new Error('not available');
		return response.json();
	}

	let detail = $state<AssetDetail>();
	let failed = $state(false);
	let newerId = $state<string>();
	let olderId = $state<string>();
	let videoFailed = $state(false);
	let fullLoaded = $state(false);
	let fullWanted = $state(preferences()?.photoFull ?? true);
	let slides = $state<SlideItem[]>();

	/** The photos loaded around this one, walked one way, when no fuller list is given. */
	function loadedSlides(from: string): SlideItem[] {
		const out: SlideItem[] = [{ id: from }];
		// eslint-disable-next-line svelte/prefer-svelte-reactivity -- a list made once, not shown
		const seen = new Set([from]);
		let at: string | undefined = from;
		while (at && out.length < 3000) {
			at = neighbours?.(at).older;
			if (!at || seen.has(at)) break;
			seen.add(at);
			out.push({ id: at });
		}
		return out;
	}

	async function startSlideshow() {
		const found = playlist ? await playlist(id).catch(() => undefined) : undefined;
		slides = found?.length ? found : loadedSlides(id);
	}

	let playingLive = $state(false);
	// A 360° panorama opens as one; the button shows it flat.
	let flat = $state(false);
	const isPanorama = $derived(detail?.projection === 'equirectangular');
	let liveDetail = $state<AssetDetail>();
	let showInfo = $state(false);
	let showActivity = $state(false);
	let confirmDelete = $state(false);
	let editingFacts = $state(false);
	let editing = $state(false);
	let revision = $state(0);
	let dialog = $state<HTMLDivElement>();

	let scale = $state(1);
	let x = $state(0);
	let y = $state(0);
	let stage = $state<HTMLDivElement>();

	const locale = $derived(lang() === 'hr' ? 'hr-HR' : 'en-GB');

	$effect(() => {
		const current = id;
		detail = undefined;
		newerId = undefined;
		olderId = undefined;
		failed = false;
		videoFailed = false;
		fullLoaded = false;
		// Read once per photo: preferences arriving later must not load the photo again.
		fullWanted = untrack(() => preferences()?.photoFull ?? true);
		playingLive = false;
		flat = false;
		liveDetail = undefined;
		scale = 1;
		x = 0;
		y = 0;
		let stale = false;
		load(current)
			.then((loaded) => {
				if (stale) return;
				detail = loaded;
				const around = neighbours?.(current);
				newerId = around ? around.newer : loaded.newerId;
				olderId = around ? around.older : loaded.olderId;
				// Next and previous photos open at once.
				for (const neighbour of [newerId, olderId]) {
					if (neighbour) new Image().src = `${base}/assets/${neighbour}/thumbnail?size=large`;
				}
			})
			.catch(() => {
				if (!stale) failed = true;
			});
		return () => {
			stale = true;
		};
	});

	onMount(() => {
		const previous = document.activeElement as HTMLElement | null;
		document.body.classList.add('viewer-open');
		holdScroll(true);
		dialog?.focus();
		return () => {
			document.body.classList.remove('viewer-open');
			holdScroll(false);
			previous?.focus?.();
		};
	});

	// A long file name may wrap after _, - and . but never inside a word.
	const breakable = (name: string) => name.replace(/([_\-.])/g, '$1\u200b');

	const go = (target: string | undefined) => {
		if (target) onNavigate(target);
	};

	function onKey(event: KeyboardEvent) {
		if (confirmDelete || editing) return;
		if (event.key === 'Escape') {
			if (showInfo) showInfo = false;
			else if (showActivity) showActivity = false;
			else onClose();
		} else if ((event.target as HTMLElement).closest?.('input,textarea')) {
			return;
		} else if (event.key === 'ArrowLeft') go(newerId);
		else if (event.key === 'ArrowRight') go(olderId);
		else if (event.key === 'i') showInfo = !showInfo;
	}

	function zoomTo(next: number, cx: number, cy: number) {
		const clamped = Math.min(MAX_SCALE, Math.max(MIN_SCALE, next));
		const box = stage?.getBoundingClientRect();
		if (!box) return;
		const originX = cx - box.left - box.width / 2;
		const originY = cy - box.top - box.height / 2;
		const factor = clamped / scale;
		// Zooming in asks for the full resolution, including HEIC and RAW.
		if (clamped >= FULL_PREVIEW_SCALE) fullWanted = true;
		x = clamped === 1 ? 0 : originX - (originX - x) * factor;
		y = clamped === 1 ? 0 : originY - (originY - y) * factor;
		scale = clamped;
	}

	function wheel(event: WheelEvent) {
		event.preventDefault();
		zoomTo(scale * Math.exp(-event.deltaY * 0.002), event.clientX, event.clientY);
	}

	// Not reactive on purpose: only the gesture code reads this.
	// eslint-disable-next-line svelte/prefer-svelte-reactivity
	const pointers = new Map<number, { x: number; y: number }>();
	let pinchStart = { distance: 0, scale: 1 };
	let dragStart: { x: number; y: number; originX: number; originY: number } | null = null;
	let lastTap = 0;

	function down(event: PointerEvent) {
		if (detail?.kind === 'video') return;
		stage?.setPointerCapture(event.pointerId);
		pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
		if (pointers.size === 2) {
			const [a, b] = [...pointers.values()];
			pinchStart = { distance: Math.hypot(a.x - b.x, a.y - b.y), scale };
			dragStart = null;
		} else if (pointers.size === 1) {
			dragStart = { x: event.clientX, y: event.clientY, originX: x, originY: y };
		}
	}

	function move(event: PointerEvent) {
		if (!pointers.has(event.pointerId)) return;
		pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
		if (pointers.size === 2) {
			const [a, b] = [...pointers.values()];
			const distance = Math.hypot(a.x - b.x, a.y - b.y);
			if (pinchStart.distance > 0) {
				zoomTo(
					(pinchStart.scale * distance) / pinchStart.distance,
					(a.x + b.x) / 2,
					(a.y + b.y) / 2
				);
			}
		} else if (dragStart && scale > 1) {
			x = dragStart.originX + event.clientX - dragStart.x;
			y = dragStart.originY + event.clientY - dragStart.y;
		}
	}

	function up(event: PointerEvent) {
		pointers.delete(event.pointerId);
		const start = dragStart;
		dragStart = null;
		if (pointers.size > 0 || !start) return;
		const dx = event.clientX - start.x;
		const dy = event.clientY - start.y;
		if (scale === 1 && Math.abs(dx) > SWIPE_DISTANCE && Math.abs(dx) > Math.abs(dy) * 1.5) {
			go(dx > 0 ? newerId : olderId);
			return;
		}
		if (Math.abs(dx) < 8 && Math.abs(dy) < 8) {
			const now = Date.now();
			if (now - lastTap < 300) {
				zoomTo(scale > 1 ? 1 : 2.5, event.clientX, event.clientY);
				lastTap = 0;
			} else {
				lastTap = now;
			}
		}
	}

	function cancel(event: PointerEvent) {
		pointers.delete(event.pointerId);
		dragStart = null;
	}

	const place = $derived([detail?.city, detail?.state, detail?.country].filter(Boolean).join(', '));
	const hasLive = $derived(Boolean(detail?.liveVideoId || detail?.hasMotion));

	// Loads the shown photo again. An answer for a photo the viewer has moved on from is dropped.
	async function reload() {
		const asked = id;
		const loaded = await load(asked);
		if (asked === id) detail = loaded;
	}

	async function toggleLive() {
		playingLive = !playingLive;
		if (playingLive && detail?.liveVideoId && !liveDetail) {
			const asked = id;
			try {
				const loaded = await load(detail.liveVideoId);
				if (asked === id) liveDetail = loaded;
			} catch {
				// It still plays directly.
			}
		}
	}

	const liveSources = $derived.by(() => {
		if (detail?.hasMotion) return { direct: `${base}/assets/${id}/motion` };
		const video = detail?.liveVideoId;
		if (!video) return undefined;
		return {
			hls: liveDetail?.hlsReady ? `${base}/assets/${video}/video/master.m3u8` : undefined,
			direct: `${base}/assets/${video}/original`
		};
	});

	async function toggleFavorite(event?: MouseEvent) {
		pulse((event?.currentTarget as HTMLElement | undefined)?.querySelector('svg'));
		if (!detail) return;
		const next = !detail.isFavorite;
		const asked = detail.id;
		try {
			await api.bulk([asked], next ? 'favorite' : 'unfavorite');
			if (detail?.id === asked) detail = { ...detail, isFavorite: next };
			onChanged();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function changeStack(action: (shot: string) => Promise<void>) {
		if (!detail) return;
		const shot = detail.id;
		try {
			await action(shot);
			await reload();
			onChanged();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function remove() {
		if (!detail) return;
		const removed = detail.id;
		try {
			await api.bulk([removed], 'delete');
			confirmDelete = false;
			onChanged();
			showToast('ok', t('viewer.deleted'));
			const next = olderId ?? newerId;
			if (next) onNavigate(next);
			else onClose();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	const settings = $derived.by(() => {
		if (!detail) return '';
		const parts = [
			detail.fNumber ? `f/${detail.fNumber}` : '',
			detail.exposureTime ? `${exposure(detail.exposureTime)} s` : '',
			detail.focalLength ? `${detail.focalLength} mm` : '',
			detail.iso ? `ISO ${detail.iso}` : ''
		];
		return parts.filter(Boolean).join(' · ');
	});

	function exposure(value: string) {
		const seconds = Number(value);
		return seconds > 0 && seconds < 1 ? `1/${Math.round(1 / seconds)}` : value;
	}
</script>

<!-- eslint-disable svelte/no-navigation-without-resolve -- downloads are API files, not pages -->
<svelte:window onkeydown={onKey} />

<div
	bind:this={dialog}
	class="viewer"
	data-lenis-prevent
	role="dialog"
	aria-modal="true"
	aria-label={detail?.originalName ?? t('viewer.photo')}
	tabindex="-1"
>
	<div class="viewer-main">
		<div class="viewer-top">
			<button type="button" class="icon-btn" aria-label={t('common.close')} onclick={onClose}
				><Icon name="back" /></button
			>
			<div class="viewer-acts">
				{#if detail}
					{#if !previewOnly}
						<button
							type="button"
							class="icon-btn"
							aria-label={t('common.slideshow')}
							title={t('common.slideshow')}
							onclick={startSlideshow}><Icon name="play" /></button
						>
					{/if}
					{#if isPanorama}
						<button
							type="button"
							class="icon-btn"
							class:viewer-on={!flat}
							aria-pressed={!flat}
							aria-label={t('viewer.360View')}
							title={t('viewer.360View')}
							onclick={() => (flat = !flat)}><Icon name="globe" /></button
						>
					{/if}
					{#if hasLive}
						<button
							type="button"
							class="icon-btn"
							class:viewer-on={playingLive}
							aria-pressed={playingLive}
							aria-label={t('viewer.playLive')}
							title={t('viewer.playLive')}
							onclick={toggleLive}><Icon name="live" /></button
						>
					{/if}
					{#if albumId}
						<button
							type="button"
							class="icon-btn"
							class:viewer-on={showActivity}
							aria-pressed={showActivity}
							aria-label={t('viewer.commentsAndHearts')}
							title={t('viewer.commentsAndHearts')}
							onclick={() => {
								showActivity = !showActivity;
								showInfo = false;
							}}><Icon name="heart" /></button
						>
					{/if}
					{#if detail.isOwner}<button
							type="button"
							class="icon-btn"
							class:viewer-on={detail.isFavorite}
							class:viewer-fav={detail.isFavorite}
							aria-pressed={detail.isFavorite}
							aria-label={t('common.favorite')}
							title={t('common.favorite')}
							onclick={toggleFavorite}><Icon name="star" /></button
						>{/if}
					{#if detail.downloadAllowed !== false}<ShareButton ids={[detail.id]} />{/if}
					{#if detail.downloadAllowed !== false}<a
							class="icon-btn"
							href="{base}/assets/{detail.id}/original?download=true"
							download
							aria-label={t('viewer.downloadTheOriginal')}
							title={t('viewer.downloadTheOriginal')}
							data-sveltekit-reload><Icon name="download" /></a
						>{/if}
					<button
						type="button"
						class="icon-btn"
						class:viewer-on={showInfo}
						aria-pressed={showInfo}
						aria-label={t('viewer.details')}
						title={t('viewer.details')}
						onclick={() => {
							showInfo = !showInfo;
							showActivity = false;
						}}><Icon name="info" /></button
					>
					{#if detail.isOwner && detail.kind === 'photo' && base === '/api' && !previewOnly}<button
							type="button"
							class="icon-btn"
							aria-label={t('viewer.edit')}
							title={t('viewer.edit')}
							onclick={() => (editing = true)}><Icon name="cog" /></button
						>{/if}
					{#if detail.isOwner}<button
							type="button"
							class="icon-btn"
							aria-label={t('common.delete')}
							title={t('common.delete')}
							onclick={() =>
								preferences()?.confirmDelete === false ? remove() : (confirmDelete = true)}
							><Icon name="trash" /></button
						>{/if}
				{/if}
			</div>
		</div>

		<div
			bind:this={stage}
			class="viewer-stage"
			role="presentation"
			onwheel={wheel}
			onpointerdown={down}
			onpointermove={move}
			onpointerup={up}
			onpointercancel={cancel}
		>
			{#if failed}
				<div class="viewer-msg">
					<Alert kind="err">{t('viewer.thisPhotoIsNotAvailable')}</Alert>
				</div>
			{:else if detail?.kind === 'video' && !videoFailed && !previewOnly}
				<VideoPlayer
					assetId={id}
					sources={{
						hls:
							detail.hlsReady && !(preferences()?.videoOriginal ?? true)
								? `${base}/assets/${id}/video/master.m3u8`
								: undefined,
						direct: `${base}/assets/${id}/original`,
						fallback: detail.hlsReady ? `${base}/assets/${id}/video/master.m3u8` : undefined
					}}
					sprite={detail.sprite}
					poster="{base}/assets/{id}/thumbnail?size=large"
					autoplay={preferences()?.videoAutoplay ?? true}
					loop={preferences()?.videoLoop ?? false}
					onFailed={() => (videoFailed = true)}
				/>
			{:else if detail?.kind === 'video' && !previewOnly}
				<div class="viewer-msg">
					<Alert kind="warn">{t('viewer.thisBrowserCannotPlayThis')}</Alert>
					{#if detail.downloadAllowed !== false}<a
							class="btn gold"
							href="{base}/assets/{id}/original?download=true"
							download
							data-sveltekit-reload><Icon name="download" size={14} /> {t('viewer.download')}</a
						>{/if}
				</div>
			{:else if detail && isPanorama && !flat && !previewOnly}
				<PanoramaView src="{base}/assets/{id}/thumbnail?size=full" alt={detail.originalName} />
			{:else if detail}
				{#key revision}<img
						class="viewer-media"
						class:under={fullWanted && fullLoaded}
						src="{base}/assets/{id}/thumbnail?size=large"
						alt={detail.originalName}
						draggable="false"
						style="transform:translate({x}px,{y}px) scale({scale})"
					/>
				{/key}
				{#if fullWanted}
					<img
						class="viewer-media viewer-full"
						class:on={fullLoaded}
						src="{base}/assets/{id}/thumbnail?size=full"
						alt=""
						draggable="false"
						style="transform:translate({x}px,{y}px) scale({scale})"
						onload={() => (fullLoaded = true)}
					/>
				{/if}
				{#if playingLive && liveSources}
					<div class="viewer-live">
						<VideoPlayer
							assetId={detail.liveVideoId ?? id}
							sources={liveSources}
							autoplay
							onFailed={() => {
								playingLive = false;
								showToast('err', t('viewer.theVideoCannotBePlayed'));
							}}
						/>
					</div>
				{/if}
			{/if}
			{#if detail?.stack && scale === 1}
				<div
					class="viewer-stack"
					role="group"
					aria-label={t('viewer.stackOfShots')}
					onpointerdown={(event) => event.stopPropagation()}
				>
					{#each detail.stack as shot, index (shot)}
						<button
							type="button"
							class="viewer-stack-shot"
							class:on={shot === id}
							aria-current={shot === id}
							aria-label={t('viewer.shotValue', { value: index + 1 })}
							onclick={() => go(shot)}
						>
							<img src="{base}/assets/{shot}/thumbnail" alt="" draggable="false" />
						</button>
					{/each}
					{#if detail.stack[0] !== id}
						<Button small onclick={() => changeStack(api.setStackMain)}
							>{t('viewer.makeItTheMainShot')}</Button
						>
					{/if}
					<Button small onclick={() => changeStack(api.dissolveStack)}
						>{t('viewer.splitTheStack')}</Button
					>
				</div>
			{/if}
			<!-- A stack shows its own shots in the same place, so the strip steps aside. -->
			{#if strip && scale === 1 && !detail?.stack}
				{@const shots = strip(id)}
				{#if shots.length > 1}
					<nav
						class="viewer-strip"
						aria-label={t('viewer.nearbyPhotos')}
						onpointerdown={(event) => event.stopPropagation()}
					>
						{#each shots as shot (shot.id)}
							<button
								type="button"
								class:on={shot.id === id}
								aria-current={shot.id === id}
								aria-label={t('viewer.openPhoto')}
								onclick={() => go(shot.id)}
							>
								<img src={thumbUrl(base, shot.id, shot.blurhash)} alt="" draggable="false" />
							</button>
						{/each}
					</nav>
				{/if}
			{/if}
			{#if newerId && scale === 1}
				<button
					type="button"
					class="icon-btn viewer-nav viewer-prev"
					aria-label={t('viewer.newer')}
					onpointerdown={(event) => event.stopPropagation()}
					onclick={() => go(newerId)}><Icon name="back" /></button
				>
			{/if}
			{#if olderId && scale === 1}
				<button
					type="button"
					class="icon-btn viewer-nav viewer-next"
					aria-label={t('viewer.older')}
					onpointerdown={(event) => event.stopPropagation()}
					onclick={() => go(olderId)}><Icon name="forward" /></button
				>
			{/if}
		</div>
	</div>

	{#if showActivity && albumId}
		<aside class="viewer-info" aria-label={t('viewer.commentsAndHearts')}>
			<div class="dlg-h">
				<h2>{t('viewer.commentsAndHearts')}</h2>
				<button
					type="button"
					class="icon-btn sm"
					aria-label={t('common.close')}
					onclick={() => (showActivity = false)}>✕</button
				>
			</div>
			<div class="dlg-b"><AlbumActivity {albumId} assetId={id} /></div>
		</aside>
	{/if}

	{#if showInfo && detail}
		<aside class="viewer-info" aria-label={t('viewer.details')}>
			<div class="dlg-h vw-head">
				<div>
					<!-- The owner's words first, then where, then when; a file name is not a title. -->
					<h2 class="vw-title">
						{detail.caption || place || formatDateTime(detail.localAt, locale)}
					</h2>
					{#if detail.caption || place}
						<p class="vw-when">
							{formatDateTime(detail.localAt, locale)}{detail.caption && place ? ` · ${place}` : ''}
						</p>
					{/if}
				</div>
				<button
					type="button"
					class="icon-btn sm"
					aria-label={t('viewer.closeDetails')}
					onclick={() => (showInfo = false)}>✕</button
				>
			</div>
			<div class="dlg-b">
				{#if detail.isMissing}
					<Alert kind="warn">{t('viewer.theFileWasNotFound')}</Alert>
				{/if}
				{#if detail.isOwner}
					<RatingStars
						assetId={id}
						rating={detail.rating ?? 0}
						onChanged={async () => {
							await reload();
						}}
					/>
				{/if}
				<Kv label={t('common.name')} value={breakable(detail.originalName)} mono />
				{#if detail.description}
					<Kv label={t('common.description')} value={detail.description} />
				{/if}
				<Kv
					label={detail.hasCaptureTime ? t('viewer.taken') : t('viewer.added')}
					value={formatDateTime(detail.localAt, locale)}
				/>
				{#if detail.width && detail.height}
					<Kv label={t('viewer.dimensions')} value="{detail.width} × {detail.height}" mono />
				{/if}
				<Kv label={t('viewer.size')} value={formatBytes(detail.sizeBytes)} />
				{#if detail.durationMs}
					<Kv label={t('viewer.duration')} value={formatDuration(detail.durationMs)} />
				{/if}
				{#if place}<Kv label={t('common.place')} value={place} />{/if}
				{#if detail.people}<FacesEditor assetId={id} />{/if}
				{#if detail.isOwner || detail.people}
					<div class="vw-acts">
						{#if detail.people}
							<Button small onclick={() => (editingFacts = true)}>
								{t('viewer.editDetails')}
							</Button>
						{/if}
						{#if detail.isOwner}
							<a class="btn sm ghost" href="/api/assets/{id}/sidecar" download
								><Icon name="download" size={14} />{t('viewer.downloadXmp')}</a
							>
						{/if}
					</div>
				{/if}
				{#if detail.tags?.length}
					<Kv label={t('common.tags')} value={detail.tags.join(', ')} />
				{/if}
				{#if detail.camera}<Kv label={t('common.camera')} value={detail.camera} mono />{/if}
				{#if detail.lens}<Kv label={t('viewer.lens')} value={detail.lens} mono />{/if}
				{#if settings}<Kv label={t('viewer.settings')} value={settings} mono />{/if}
				{#if detail.latitude !== undefined && detail.longitude !== undefined}
					<Kv
						label={t('common.location')}
						mono
						value="{detail.latitude.toFixed(5)}, {detail.longitude.toFixed(5)}"
					/>
				{/if}
			</div>
		</aside>
	{/if}
</div>

{#if editing && detail}
	<PhotoEditor
		{detail}
		onClose={() => (editing = false)}
		onSaved={async () => {
			editing = false;
			revision += 1;
			await reload();
			onChanged();
		}}
	/>
{/if}

{#if editingFacts && detail}
	<AssetFactsDialog
		{detail}
		onClose={() => (editingFacts = false)}
		onSaved={async () => {
			editingFacts = false;
			await reload();
			onChanged();
		}}
	/>
{/if}

<Dialog title={t('viewer.deleteThisPhoto')} bind:open={confirmDelete}>
	<p>
		{t('viewer.itMovesToTheTrash', { trashDays: trashDays() })}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmDelete = false)}>{t('common.cancel')}</Button>
		<Button variant="danger" onclick={remove}>{t('common.delete')}</Button>
	{/snippet}
</Dialog>

{#if slides}
	<Slideshow
		items={slides}
		startId={id}
		{base}
		onClose={(last) => {
			slides = undefined;
			if (last !== id) onNavigate(last);
		}}
	/>
{/if}
