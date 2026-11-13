<script lang="ts">
	import { onMount } from 'svelte';
	import { api } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import { holdScroll } from '#lib/motion/motion.ts';
	import { openLayer, type Layer } from '#lib/design/layers.ts';
	import {
		actualSizeScale,
		chunks,
		keyAction,
		preloadIds,
		toggleCompared,
		withPick,
		type Mark
	} from './cull.ts';

	type Photo = { id: string };

	const SWIPE_DISTANCE = 60;
	const STARS = [1, 2, 3, 4, 5];

	let { items, onClose }: { items: Photo[]; onClose: () => void } = $props();

	// The list shrinks as photos go to the trash; it starts from what was opened.
	// svelte-ignore state_referenced_locally
	let photos = $state.raw<Photo[]>(items);
	let marks = $state<Record<string, Mark>>();
	let index = $state(0);
	let compared = $state.raw<string[]>([]);
	let zoomed = $state(false);
	let fullReady = $state<Record<string, boolean>>({});
	// The real size of each photo, known once its full picture has been seen.
	const natural: Record<string, { width: number; height: number }> = {};
	let scale = $state(1);
	let x = $state(0);
	let y = $state(0);
	let stageWidth = $state(0);
	let stageHeight = $state(0);
	let confirmTrash = $state(false);
	let makingAlbum = $state(false);
	let albumTitle = $state('');
	let busy = $state(false);
	let root = $state<HTMLDivElement>();

	const ids = $derived(photos.map((photo) => photo.id));
	const current = $derived(photos[Math.min(index, photos.length - 1)]);
	const comparing = $derived(compared.length >= 2);
	const shown = $derived(
		comparing ? photos.filter((photo) => compared.includes(photo.id)) : current ? [current] : []
	);
	const mark = $derived(current && marks ? marks[current.id] : undefined);
	const picked = $derived(marks ? withPick(ids, marks, 1) : []);
	const rejected = $derived(marks ? withPick(ids, marks, -1) : []);

	// Decoded ahead, so that moving on shows the photo at once.
	$effect(() => {
		for (const id of preloadIds(ids, index)) {
			const image = new Image();
			image.src = `/api/assets/${id}/thumbnail?size=large`;
			image.decode().catch(() => undefined);
		}
	});

	async function loadMarks() {
		const found: Record<string, Mark> = {};
		try {
			for (const part of chunks(items.map((photo) => photo.id))) {
				const { items: states } = await api.readPicks(part);
				for (const state of states) found[state.id] = { pick: state.pick, rating: state.rating };
			}
		} catch {
			showToast('err', t('common.theActionFailed'));
			onClose();
			return;
		}
		// Only the user's own photos can be marked; others are not part of this.
		photos = items.filter((photo) => found[photo.id]);
		marks = found;
		if (!photos.length) {
			showToast('warn', t('cull.nothingToGoThrough'));
			onClose();
		}
	}

	let layer: Layer | undefined;

	onMount(() => {
		const previous = document.activeElement as HTMLElement | null;
		const own = openLayer();
		layer = own;
		document.body.classList.add('viewer-open');
		holdScroll(true);
		root?.focus();
		loadMarks();
		return () => {
			own.close();
			document.body.classList.remove('viewer-open');
			holdScroll(false);
			previous?.focus?.();
		};
	});

	function resetZoom() {
		zoomed = false;
		scale = 1;
		x = 0;
		y = 0;
	}

	function move(by: number) {
		if (comparing) {
			const at = compared.indexOf(current?.id ?? '');
			const next = compared[at + by];
			if (next) index = ids.indexOf(next);
			return;
		}
		const next = index + by;
		if (next < 0 || next >= photos.length) return;
		index = next;
		resetZoom();
	}

	function jump(to: number) {
		index = to;
		if (!comparing) resetZoom();
	}

	const stageBox = () => ({ width: stageWidth / shown.length, height: stageHeight });

	function toggleZoom() {
		if (zoomed) {
			resetZoom();
			return;
		}
		scale = actualSizeScale((current && natural[current.id]) ?? {}, stageBox());
		zoomed = true;
	}

	function fullLoaded(photo: Photo, image: HTMLImageElement) {
		fullReady[photo.id] = true;
		natural[photo.id] = { width: image.naturalWidth, height: image.naturalHeight };
		if (zoomed && photo.id === current?.id) scale = actualSizeScale(natural[photo.id], stageBox());
	}

	async function setPick(value: number) {
		if (!current || !marks) return;
		const { id } = current;
		const before = marks[id].pick;
		const next = value !== 0 && before === value ? 0 : value;
		marks[id].pick = next;
		// A verdict is the end of this photo; undoing one stays on it.
		if (next !== 0 && !comparing) move(1);
		try {
			const { changed } = await api.setPicks([id], next);
			if (!changed) throw new Error('not marked');
		} catch {
			if (marks) marks[id].pick = before;
			showToast('err', t('common.notSaved'));
		}
	}

	async function rate(value: number) {
		if (!current || !marks) return;
		const { id } = current;
		const before = marks[id].rating;
		const next = value === before ? 0 : value;
		marks[id].rating = next;
		try {
			await api.setAssetFacts(id, { rating: next });
		} catch {
			if (marks) marks[id].rating = before;
			showToast('err', t('common.notSaved'));
		}
	}

	function compare() {
		if (current) compared = toggleCompared(compared, current.id);
		resetZoom();
	}

	function stopComparing() {
		compared = [];
		resetZoom();
	}

	function onKey(event: KeyboardEvent) {
		if (confirmTrash || makingAlbum) return;
		if (event.defaultPrevented || !layer?.isTop()) return;
		if (event.key === 'Escape') {
			if (comparing) stopComparing();
			else onClose();
			return;
		}
		if (event.ctrlKey || event.metaKey || event.altKey) return;
		if ((event.target as HTMLElement).closest?.('input,textarea')) return;
		const action = keyAction(event.key);
		if (!action) return;
		event.preventDefault();
		if (action.type === 'pick') setPick(action.value);
		else if (action.type === 'rate') rate(action.value);
		else if (action.type === 'move') move(action.by);
		else if (action.type === 'zoom') toggleZoom();
		else compare();
	}

	let drag: { x: number; y: number; originX: number; originY: number; touch: boolean } | null =
		null;

	function down(event: PointerEvent) {
		(event.currentTarget as HTMLElement).setPointerCapture(event.pointerId);
		drag = {
			x: event.clientX,
			y: event.clientY,
			originX: x,
			originY: y,
			touch: event.pointerType !== 'mouse'
		};
	}

	function pointerMove(event: PointerEvent) {
		if (!drag || !zoomed) return;
		x = drag.originX + event.clientX - drag.x;
		y = drag.originY + event.clientY - drag.y;
	}

	function up(event: PointerEvent) {
		const start = drag;
		drag = null;
		if (!start || zoomed || !start.touch) return;
		const dx = event.clientX - start.x;
		const dy = event.clientY - start.y;
		if (Math.abs(dy) > SWIPE_DISTANCE && Math.abs(dy) > Math.abs(dx) * 1.5) {
			setPick(dy < 0 ? 1 : -1);
		} else if (Math.abs(dx) > SWIPE_DISTANCE && Math.abs(dx) > Math.abs(dy) * 1.5) {
			move(dx > 0 ? -1 : 1);
		}
	}

	async function trashRejected() {
		const gone = [...rejected];
		busy = true;
		try {
			for (const part of chunks(gone)) await api.bulk(part, 'delete');
			confirmTrash = false;
			showToast('ok', t('cull.movedToTrash', { count: gone.length }));
			compared = compared.filter((id) => !gone.includes(id));
			photos = photos.filter((photo) => !gone.includes(photo.id));
			index = Math.max(0, Math.min(index, photos.length - 1));
			resetZoom();
			if (!photos.length) onClose();
		} catch {
			showToast('err', t('common.theActionFailed'));
		} finally {
			busy = false;
		}
	}

	async function picksToAlbum(event: SubmitEvent) {
		event.preventDefault();
		const chosen = [...picked];
		busy = true;
		try {
			const album = await api.createAlbum({ title: albumTitle.trim() });
			for (const part of chunks(chosen)) await api.addToAlbum(album.id, part);
			makingAlbum = false;
			albumTitle = '';
			showToast('ok', t('cull.albumMade', { count: chosen.length, title: album.title }));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theAlbumWasNotCreated'));
		} finally {
			busy = false;
		}
	}
</script>

<svelte:window onkeydown={onKey} />

<div
	bind:this={root}
	class="viewer cull"
	data-lenis-prevent
	role="dialog"
	aria-modal="true"
	aria-label={t('cull.title')}
	tabindex="-1"
>
	<div class="cull-top">
		<button type="button" class="icon-btn" aria-label={t('common.close')} onclick={onClose}
			><Icon name="back" /></button
		>
		<span class="cull-at" data-testid="cull-position">{index + 1} / {photos.length}</span>
		{#if marks}
			<span class="cull-tally" data-testid="cull-tally">
				{t('cull.tally', { picks: picked.length, rejects: rejected.length })}
			</span>
		{:else}
			<Skeleton height="16px" width="120px" />
		{/if}
		<div class="cull-acts">
			<Button small onclick={compare} disabled={!current}>
				<Icon name="copy" size={14} />
				{compared.includes(current?.id ?? '')
					? t('cull.removeFromCompare')
					: t('cull.addToCompare')}
			</Button>
			{#if compared.length}
				<Button small onclick={stopComparing}>{t('cull.stopComparing')}</Button>
			{/if}
			<Button small onclick={toggleZoom} aria-pressed={zoomed}>
				<Icon name="search" size={14} />
				{zoomed ? t('cull.fit') : '100 %'}
			</Button>
			<Button small disabled={!picked.length} onclick={() => (makingAlbum = true)}>
				<Icon name="album" size={14} />
				{t('cull.picksToAlbum')}
			</Button>
			<Button
				small
				variant="danger"
				disabled={!rejected.length}
				onclick={() => (confirmTrash = true)}
			>
				<Icon name="trash" size={14} />
				{t('cull.rejectsToTrash')}
			</Button>
		</div>
	</div>

	<div
		class="cull-stage"
		class:grabbing={zoomed}
		style="--cull-columns:{shown.length === 3 ? 3 : Math.min(shown.length, 2)}"
		bind:clientWidth={stageWidth}
		bind:clientHeight={stageHeight}
		role="presentation"
		onpointerdown={down}
		onpointermove={pointerMove}
		onpointerup={up}
		onpointercancel={() => (drag = null)}
	>
		{#each shown as photo (photo.id)}
			<button
				type="button"
				class="cull-pane"
				class:on={comparing && photo.id === current?.id}
				aria-label={t('cull.photo')}
				onclick={() => (index = ids.indexOf(photo.id))}
			>
				<img
					class="viewer-media"
					class:under={zoomed && fullReady[photo.id]}
					src="/api/assets/{photo.id}/thumbnail?size=large"
					alt=""
					draggable="false"
					style="transform:translate({x}px,{y}px) scale({scale})"
				/>
				{#if zoomed}
					<img
						class="viewer-media viewer-full"
						class:on={fullReady[photo.id]}
						src="/api/assets/{photo.id}/thumbnail?size=full"
						alt=""
						draggable="false"
						style="transform:translate({x}px,{y}px) scale({scale})"
						onload={(event) => fullLoaded(photo, event.currentTarget as HTMLImageElement)}
					/>
				{/if}
				{#if marks?.[photo.id]?.pick}
					<span class="cull-flag" class:reject={marks[photo.id].pick < 0}>
						<Icon name={marks[photo.id].pick > 0 ? 'check' : 'x'} size={16} />
					</span>
				{/if}
			</button>
		{/each}
	</div>

	<div class="cull-bar">
		<div class="cull-marks" role="group" aria-label={t('cull.mark')}>
			<Button
				small
				variant={mark?.pick === 1 ? 'gold' : undefined}
				aria-pressed={mark?.pick === 1}
				disabled={!mark}
				onclick={() => setPick(1)}
			>
				<Icon name="check" size={14} />
				{t('cull.pick')}
			</Button>
			<Button
				small
				variant={mark?.pick === -1 ? 'danger' : undefined}
				aria-pressed={mark?.pick === -1}
				disabled={!mark}
				onclick={() => setPick(-1)}
			>
				<Icon name="x" size={14} />
				{t('cull.reject')}
			</Button>
			<Button small aria-pressed={mark?.pick === 0} disabled={!mark} onclick={() => setPick(0)}>
				{t('cull.noMark')}
			</Button>
		</div>
		<div class="stars" role="group" aria-label={t('ratingStars.rating')}>
			{#each STARS as stars (stars)}
				<button
					type="button"
					class="star"
					class:on={stars <= (mark?.rating ?? 0)}
					aria-pressed={stars === mark?.rating}
					aria-label={t('ratingStars.starsOf5Stars', { stars })}
					disabled={!mark}
					onclick={() => rate(stars)}>★</button
				>
			{/each}
		</div>
	</div>

	<div class="cull-strip" aria-label={t('cull.photos')}>
		{#each photos as photo, at (photo.id)}
			<button
				type="button"
				class="cull-thumb"
				class:on={at === index}
				class:picked={marks?.[photo.id]?.pick === 1}
				class:rejected={marks?.[photo.id]?.pick === -1}
				aria-label={t('cull.goToPhoto', { number: at + 1 })}
				aria-current={at === index}
				onclick={() => jump(at)}
			>
				<img
					src="/api/assets/{photo.id}/thumbnail?size=small"
					alt=""
					loading="lazy"
					decoding="async"
				/>
			</button>
		{/each}
	</div>
</div>

<Dialog title={t('cull.rejectsToTrash')} bind:open={confirmTrash}>
	<p>{t('cull.confirmTrash', { count: rejected.length })}</p>
	{#snippet footer()}
		<Button onclick={() => (confirmTrash = false)}>{t('common.cancel')}</Button>
		<Button variant="danger" disabled={busy} onclick={trashRejected}>{t('common.delete')}</Button>
	{/snippet}
</Dialog>

<Dialog title={t('cull.picksToAlbum')} bind:open={makingAlbum}>
	<form id="cull-album" class="form" onsubmit={picksToAlbum}>
		<Input label={t('common.name')} required maxlength={200} bind:value={albumTitle} />
		<p class="alb-meta">{t('cull.albumWillHold', { count: picked.length })}</p>
	</form>
	{#snippet footer()}
		<Button onclick={() => (makingAlbum = false)}>{t('common.cancel')}</Button>
		<Button type="submit" form="cull-album" variant="gold" disabled={busy || !albumTitle.trim()}
			>{t('albums.id.create')}</Button
		>
	{/snippet}
</Dialog>
