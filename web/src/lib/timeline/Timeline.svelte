<script lang="ts">
	import { onMount, untrack, type Snippet } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';
	import { resolve } from '$app/paths';
	import { api, librarySource, type TimelineItem, type TimelineSource } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, tr } from '#lib/i18n.svelte.ts';
	import { blurUrl } from './blur.ts';
	import {
		estimateMonthHeight,
		formatDay,
		formatDuration,
		formatMonth,
		layoutMonth,
		rowsInRange,
		type MonthLayout
	} from './layout.ts';
	import Scrubber from './Scrubber.svelte';

	const LOAD_AHEAD = 1.5;
	const RENDER_AHEAD = 0.75;
	const LONG_PRESS_MS = 450;
	const MOVE_TOLERANCE = 10;
	const ZIP_LIMIT = 100;

	type Month = {
		month: string;
		count: number;
		items?: TimelineItem[];
		layout?: MonthLayout;
		loading?: boolean;
		failed?: boolean;
	};

	let {
		onOpen,
		onCount,
		source = librarySource,
		base = '/api',
		hrefFor,
		selectable = true,
		ownActions = true,
		downloads = true,
		selectionActions
	}: {
		onOpen: (id: string) => void;
		onCount?: (total: number | undefined) => void;
		source?: TimelineSource;
		base?: string;
		hrefFor?: (id: string) => string;
		selectable?: boolean;
		ownActions?: boolean;
		downloads?: boolean;
		selectionActions?: Snippet<[string[], () => void]>;
	} = $props();

	let months = $state.raw<Month[] | undefined>(undefined);
	let loadFailed = $state(false);
	let container = $state<HTMLDivElement>();
	let width = $state(0);
	let scrollY = $state(0);
	let viewportHeight = $state(800);
	let containerTop = $state(0);

	const selected = new SvelteSet<string>();
	let lastIndex = $state<{ month: string; index: number } | null>(null);
	let confirmDelete = $state(false);
	let dragBox = $state<{ x1: number; y1: number; x2: number; y2: number } | null>(null);
	let busy = $state(false);

	const locale = $derived(lang() === 'hr' ? 'hr-HR' : 'en-GB');
	const selecting = $derived(selected.size > 0);

	// Where each month starts. Months that are not loaded use an estimate.
	const placed = $derived.by(() => {
		let top = 0;
		return (months ?? []).map((entry) => {
			const height = entry.layout?.height ?? estimateMonthHeight(entry.count, width || 1000);
			const out = { entry, top, height };
			top += height;
			return out;
		});
	});
	const totalHeight = $derived(
		placed.length ? placed[placed.length - 1].top + placed[placed.length - 1].height : 0
	);
	const position = $derived(Math.max(0, scrollY - containerTop));

	const visible = $derived.by(() => {
		const from = position - viewportHeight * RENDER_AHEAD;
		const to = position + viewportHeight * (1 + RENDER_AHEAD);
		return placed.filter(({ top, height }) => top + height >= from && top <= to);
	});

	const marks = $derived(
		placed.map(({ entry, top }) => ({
			month: entry.month,
			top,
			label: formatMonth(entry.month, locale)
		}))
	);

	function measure() {
		scrollY = window.scrollY;
		viewportHeight = window.innerHeight;
		if (container) containerTop = container.getBoundingClientRect().top + window.scrollY;
	}

	function buildLayout(entry: Month, items: TimelineItem[], forWidth: number) {
		return layoutMonth(items, forWidth, formatMonth(entry.month, locale), (localAt) =>
			formatDay(localAt, locale)
		);
	}

	function updateMonth(month: string, change: (entry: Month) => Month) {
		months = months?.map((entry) => (entry.month === month ? change(entry) : entry));
	}

	/** Replaces a month, keeping the photos on screen still when a month above it changes height. */
	function applyLoaded(month: string, items: TimelineItem[]) {
		const index = placed.findIndex(({ entry }) => entry.month === month);
		if (index < 0) return;
		const { top, height, entry } = placed[index];
		const layout = buildLayout(entry, items, width || 1000);
		const above = top + height <= position;
		updateMonth(month, (current) => ({
			...current,
			count: items.length,
			items,
			layout,
			loading: false,
			failed: false
		}));
		if (above && layout.height !== height) window.scrollBy(0, layout.height - height);
	}

	async function loadMonth(month: string) {
		updateMonth(month, (entry) => ({ ...entry, loading: true, failed: false }));
		try {
			const bucket = await source.bucket(month);
			applyLoaded(month, bucket.items);
		} catch {
			updateMonth(month, (entry) => ({ ...entry, loading: false, failed: true }));
		}
	}

	// Load months as they approach the screen.
	$effect(() => {
		const from = position - viewportHeight * LOAD_AHEAD;
		const to = position + viewportHeight * (1 + LOAD_AHEAD);
		for (const { entry, top, height } of placed) {
			if (entry.items || entry.loading || entry.failed) continue;
			if (top + height >= from && top <= to) untrack(() => loadMonth(entry.month));
		}
	});

	// The layout depends on the width and on the language of the headers.
	$effect(() => {
		const forWidth = width;
		void locale;
		if (!forWidth) return;
		untrack(() => {
			if (!months?.some((entry) => entry.items)) return;
			months = months.map((entry) =>
				entry.items ? { ...entry, layout: buildLayout(entry, entry.items, forWidth) } : entry
			);
		});
	});

	/** Reads what changed. Months whose counts are the same are not fetched again. */
	export async function refresh(force: string[] = []) {
		try {
			const { buckets } = await source.buckets();
			loadFailed = false;
			const known = new Map((months ?? []).map((entry) => [entry.month, entry]));
			const stale: string[] = [];
			months = buckets.map(({ month, count }) => {
				const entry = known.get(month);
				if (!entry) return { month, count };
				if (entry.items && (entry.count !== count || force.includes(month))) stale.push(month);
				return { ...entry, count };
			});
			onCount?.(buckets.reduce((sum, bucket) => sum + bucket.count, 0));
			for (const month of stale) await loadMonth(month);
		} catch {
			loadFailed = true;
			if (!months) onCount?.(undefined);
		}
	}

	/** Reloads everything loaded, after an action that changes photos but maybe not counts. */
	export function reloadLoaded() {
		return refresh((months ?? []).filter((entry) => entry.items).map((entry) => entry.month));
	}

	onMount(() => {
		measure();
		refresh();
		let frame = 0;
		const schedule = () => {
			if (!frame) {
				frame = requestAnimationFrame(() => {
					frame = 0;
					measure();
				});
			}
		};
		window.addEventListener('scroll', schedule, { passive: true });
		window.addEventListener('resize', schedule);
		return () => {
			window.removeEventListener('scroll', schedule);
			window.removeEventListener('resize', schedule);
			cancelAnimationFrame(frame);
		};
	});

	/** The photos before and after this one, as shown here. Months not loaded yet are not known. */
	export function neighbours(id: string) {
		const items = allItems();
		const index = items.findIndex((item) => item.id === id);
		if (index < 0) return {};
		return { newer: items[index - 1]?.id, older: items[index + 1]?.id };
	}

	function allItems() {
		return (months ?? []).flatMap((entry) => entry.items ?? []);
	}

	function toggle(id: string) {
		if (selected.has(id)) selected.delete(id);
		else selected.add(id);
	}

	function selectRange(month: string, index: number) {
		if (!lastIndex) return;
		const order = (months ?? []).map((entry) => entry.month);
		const a = { monthIndex: order.indexOf(lastIndex.month), index: lastIndex.index };
		const b = { monthIndex: order.indexOf(month), index };
		const [first, last] =
			a.monthIndex < b.monthIndex || (a.monthIndex === b.monthIndex && a.index <= b.index)
				? [a, b]
				: [b, a];
		for (let m = first.monthIndex; m <= last.monthIndex; m++) {
			const items = months?.[m].items ?? [];
			const from = m === first.monthIndex ? first.index : 0;
			const to = m === last.monthIndex ? last.index : items.length - 1;
			for (let i = from; i <= to; i++) selected.add(items[i].id);
		}
	}

	let longPress = 0;
	let pressStart: { x: number; y: number } | null = null;
	let pressed = false;

	function tileDown(event: PointerEvent, id: string, month: string, index: number) {
		pressed = false;
		if (!selectable || event.pointerType === 'mouse') return;
		pressStart = { x: event.clientX, y: event.clientY };
		clearTimeout(longPress);
		longPress = window.setTimeout(() => {
			pressed = true;
			selected.add(id);
			lastIndex = { month, index };
			navigator.vibrate?.(10);
		}, LONG_PRESS_MS);
	}

	function tileMove(event: PointerEvent) {
		if (!pressStart) return;
		const moved = Math.hypot(event.clientX - pressStart.x, event.clientY - pressStart.y);
		if (moved > MOVE_TOLERANCE) cancelPress();
	}

	function cancelPress() {
		clearTimeout(longPress);
		pressStart = null;
	}

	function tileClick(event: MouseEvent, id: string, month: string, index: number) {
		event.preventDefault();
		if (pressed) {
			pressed = false;
			return;
		}
		if (!selectable) {
			onOpen(id);
			return;
		}
		if (event.shiftKey && lastIndex) {
			selectRange(month, index);
		} else if (selecting || event.ctrlKey || event.metaKey) {
			toggle(id);
		} else {
			onOpen(id);
			return;
		}
		lastIndex = { month, index };
	}

	function checkClick(event: MouseEvent, id: string, month: string, index: number) {
		event.preventDefault();
		event.stopPropagation();
		if (event.shiftKey && lastIndex) selectRange(month, index);
		else toggle(id);
		lastIndex = { month, index };
	}

	// Drag on the empty space between photos to select with a box. Mouse only: touch scrolls.
	function gridDown(event: PointerEvent) {
		if (!selectable || event.pointerType !== 'mouse' || event.button !== 0) return;
		if ((event.target as HTMLElement).closest('.tl-tile')) return;
		const x = event.pageX;
		const y = event.pageY;
		dragBox = { x1: x, y1: y, x2: x, y2: y };
		window.addEventListener('pointermove', gridMove);
		window.addEventListener('pointerup', gridUp, { once: true });
		event.preventDefault();
	}

	function gridMove(event: PointerEvent) {
		if (dragBox) dragBox = { ...dragBox, x2: event.pageX, y2: event.pageY };
	}

	function gridUp() {
		window.removeEventListener('pointermove', gridMove);
		const box = dragBox;
		dragBox = null;
		if (!box || !container) return;
		const left = Math.min(box.x1, box.x2);
		const right = Math.max(box.x1, box.x2);
		const top = Math.min(box.y1, box.y2);
		const bottom = Math.max(box.y1, box.y2);
		if (right - left < 4 && bottom - top < 4) return;
		const originX = container.getBoundingClientRect().left + window.scrollX;
		for (const { entry, top: monthTop } of placed) {
			for (const row of entry.layout?.rows ?? []) {
				if (row.type !== 'tiles') continue;
				const rowTop = containerTop + monthTop + row.top;
				if (rowTop > bottom || rowTop + row.height < top) continue;
				for (const tile of row.tiles) {
					if (originX + tile.x <= right && originX + tile.x + tile.width >= left) {
						selected.add(tile.item.id);
					}
				}
			}
		}
	}

	function onKey(event: KeyboardEvent) {
		if (event.key === 'Escape' && selecting && !confirmDelete) selected.clear();
	}

	async function act(action: 'favorite' | 'unfavorite' | 'archive' | 'delete') {
		const ids = [...selected];
		busy = true;
		try {
			await api.bulk(ids, action);
			selected.clear();
			lastIndex = null;
			await reloadLoaded();
			if (action === 'delete') {
				showToast('ok', tr(`Obrisano: ${ids.length}`, `Deleted: ${ids.length}`));
			} else if (action === 'archive') {
				showToast('ok', tr(`Arhivirano: ${ids.length}`, `Archived: ${ids.length}`));
			}
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		} finally {
			busy = false;
			confirmDelete = false;
		}
	}

	const allFavorite = $derived(
		selecting &&
			allItems()
				.filter((item) => selected.has(item.id))
				.every((item) => item.isFavorite)
	);
	const downloadUrl = $derived(
		selected.size === 1
			? `${base}/assets/${[...selected][0]}/original?download=true`
			: `${base}/assets/download?ids=${[...selected].join(',')}`
	);
</script>

<!-- eslint-disable svelte/no-navigation-without-resolve -- downloads are API files, not pages -->
<svelte:window onkeydown={onKey} />

{#if loadFailed}
	<Alert kind="err">{tr('Fotke se nisu učitale.', 'Photos could not be loaded.')}</Alert>
{/if}

{#if months === undefined && !loadFailed}
	<div class="form" aria-hidden="true">
		<Skeleton height="44px" width="40%" /><Skeleton height="220px" />
	</div>
{/if}

<div
	class="tl"
	bind:this={container}
	bind:clientWidth={width}
	style="height:{totalHeight}px"
	role="presentation"
	onpointerdown={gridDown}
>
	{#each visible as { entry, top, height } (entry.month)}
		<div class="tl-mo" style="top:{top}px;height:{height}px">
			{#if entry.layout}
				{#each rowsInRange(entry.layout.rows, position - top - viewportHeight * RENDER_AHEAD, position - top + viewportHeight * (1 + RENDER_AHEAD)) as row (row.top)}
					{#if row.type === 'month'}
						<h2 class="tl-month" style="top:{row.top}px;height:{row.height}px">{row.label}</h2>
					{:else if row.type === 'day'}
						<h3 class="tl-day" style="top:{row.top}px;height:{row.height}px">{row.label}</h3>
					{:else}
						{#each row.tiles as tile (tile.item.id)}
							{@const blur = blurUrl(tile.item.blurhash)}
							<a
								class="tl-tile"
								class:sel={selected.has(tile.item.id)}
								href={hrefFor?.(tile.item.id) ??
									resolve('/(app)/photos/[id]', { id: tile.item.id })}
								draggable="false"
								style="top:{row.top}px;left:{tile.x}px;width:{tile.width}px;height:{row.height}px;{blur
									? `background-image:url(${blur})`
									: ''}"
								aria-label={formatDay(tile.item.localAt, locale)}
								onclick={(event) => tileClick(event, tile.item.id, entry.month, tile.index)}
								onpointerdown={(event) => tileDown(event, tile.item.id, entry.month, tile.index)}
								onpointermove={tileMove}
								onpointerup={cancelPress}
								onpointercancel={cancelPress}
								oncontextmenu={(event) => {
									if (pressStart || pressed) event.preventDefault();
								}}
							>
								<img
									src="{base}/assets/{tile.item.id}/thumbnail"
									alt=""
									decoding="async"
									draggable="false"
								/>
								{#if tile.item.kind === 'video'}
									<span class="tl-badge tl-video">
										{#if tile.item.durationMs}<small>{formatDuration(tile.item.durationMs)}</small
											>{/if}
										<Icon name="play" size={14} />
									</span>
								{/if}
								{#if tile.item.isLive}
									<span class="tl-badge tl-live" title="Live"><Icon name="live" size={14} /></span>
								{/if}
								{#if tile.item.isFavorite}
									<span class="tl-badge tl-fav"><Icon name="star" size={14} /></span>
								{/if}
								{#if selectable}
									<button
										type="button"
										class="tl-check"
										aria-label={tr('Odaberi', 'Select')}
										aria-pressed={selected.has(tile.item.id)}
										onclick={(event) => checkClick(event, tile.item.id, entry.month, tile.index)}
									>
										<Icon name="check" size={14} />
									</button>
								{/if}
							</a>
						{/each}
					{/if}
				{/each}
			{:else if entry.failed}
				<div class="tl-fail">
					<Alert kind="err"
						>{tr('Ovaj mjesec se nije učitao.', 'This month could not be loaded.')}</Alert
					>
					<Button small onclick={() => loadMonth(entry.month)}
						>{tr('Pokušaj ponovno', 'Try again')}</Button
					>
				</div>
			{:else}
				<div class="tl-wait"><Skeleton height="100%" /></div>
			{/if}
		</div>
	{/each}
</div>

{#if dragBox}
	<div
		class="tl-box"
		style="left:{Math.min(dragBox.x1, dragBox.x2)}px;top:{Math.min(
			dragBox.y1,
			dragBox.y2
		)}px;width:{Math.abs(dragBox.x2 - dragBox.x1)}px;height:{Math.abs(dragBox.y2 - dragBox.y1)}px"
	></div>
{/if}

{#if totalHeight > viewportHeight * 2}
	<Scrubber
		{marks}
		total={totalHeight}
		{position}
		onSeek={(y) => window.scrollTo(0, containerTop + Math.max(0, y))}
	/>
{/if}

{#if selecting}
	<div class="selbar glass" role="toolbar" aria-label={tr('Odabrane fotke', 'Selected photos')}>
		<button
			type="button"
			class="icon-btn sm"
			aria-label={tr('Poništi odabir', 'Clear selection')}
			onclick={() => selected.clear()}>✕</button
		>
		<b class="selbar-n">{selected.size}</b>
		<div class="selbar-a">
			{@render selectionActions?.([...selected], () => selected.clear())}
			{#if ownActions}<button
					type="button"
					class="icon-btn"
					disabled={busy}
					aria-label={allFavorite
						? tr('Makni iz favorita', 'Remove from favorites')
						: tr('Dodaj u favorite', 'Add to favorites')}
					title={allFavorite
						? tr('Makni iz favorita', 'Remove from favorites')
						: tr('Dodaj u favorite', 'Add to favorites')}
					onclick={() => act(allFavorite ? 'unfavorite' : 'favorite')}><Icon name="star" /></button
				>{/if}
			{#if !downloads}
				<!-- This place offers no downloads. -->
			{:else if selected.size <= ZIP_LIMIT}
				<a
					class="icon-btn"
					href={downloadUrl}
					download
					aria-label={tr('Preuzmi', 'Download')}
					title={tr('Preuzmi', 'Download')}
					data-sveltekit-reload><Icon name="download" /></a
				>
			{:else}
				<button
					type="button"
					class="icon-btn"
					aria-label={tr('Preuzmi', 'Download')}
					title={tr('Preuzmi', 'Download')}
					onclick={() =>
						showToast(
							'warn',
							tr(
								`Odjednom se može preuzeti najviše ${ZIP_LIMIT} datoteka.`,
								`You can download at most ${ZIP_LIMIT} files at once.`
							)
						)}><Icon name="download" /></button
				>
			{/if}
			{#if ownActions}<button
					type="button"
					class="icon-btn"
					disabled={busy}
					aria-label={tr('Arhiviraj', 'Archive')}
					title={tr('Arhiviraj', 'Archive')}
					onclick={() => act('archive')}><Icon name="archive" /></button
				>
				<button
					type="button"
					class="icon-btn"
					disabled={busy}
					aria-label={tr('Obriši', 'Delete')}
					title={tr('Obriši', 'Delete')}
					onclick={() => (confirmDelete = true)}><Icon name="trash" /></button
				>{/if}
		</div>
	</div>
{/if}

<Dialog title={tr('Obrisati odabrano?', 'Delete the selection?')} bind:open={confirmDelete}>
	<p>
		{tr(
			`Odabrano: ${selected.size}. Nestat će iz prikaza. Smeće s vraćanjem stiže u kasnijoj verziji, a do tada se vraća samo ponovnim uploadom iste datoteke.`,
			`Selected: ${selected.size}. They will disappear from view. A trash with restore arrives in a later version; until then, uploading the same file again brings it back.`
		)}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmDelete = false)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" disabled={busy} onclick={() => act('delete')}
			>{tr('Obriši', 'Delete')}</Button
		>
	{/snippet}
</Dialog>
