<script lang="ts">
	import {
		api,
		formatBytes,
		type CleanupCategoryId,
		type CleanupItem,
		type CleanupSummary
	} from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { dateLocale, t } from '#lib/i18n.svelte.ts';
	import {
		CATEGORIES,
		VIDEO_SIZES,
		hintOf,
		lengthOf,
		ticked,
		titleOf
	} from '#lib/organize/cleanup.ts';
	import { trashDays } from '#lib/preferences.svelte.ts';
	import VideoPlayer from '#lib/timeline/VideoPlayer.svelte';

	let summary = $state<CleanupSummary>();
	let failed = $state(false);
	let category = $state<CleanupCategoryId>('blurry');
	let blur = $state(3);
	let videoMb = $state<number>(500);
	let items = $state<CleanupItem[]>();
	let nextOffset = $state<number>();
	// What the person changed by hand; the rest follows `ticked`.
	let choices = $state<Record<string, boolean>>({});
	let confirming = $state(false);
	let working = $state(false);
	let playing = $state<CleanupItem>();

	const isTicked = (item: CleanupItem) => choices[item.id] ?? ticked(item);
	const chosen = $derived((items ?? []).filter(isTicked));
	const chosenBytes = $derived(chosen.reduce((sum, item) => sum + item.sizeBytes, 0));

	async function loadSummary() {
		try {
			summary = await api.cleanup(blur, videoMb);
			failed = false;
		} catch {
			failed = true;
		}
	}

	async function loadItems(more = false) {
		try {
			const page = await api.cleanupPage(category, blur, videoMb, more ? (nextOffset ?? 0) : 0);
			items = more ? [...(items ?? []), ...page.items] : page.items;
			nextOffset = page.nextOffset;
		} catch {
			failed = true;
		}
	}

	$effect(() => {
		// Read here, so that a change of any of them loads again.
		void [category, blur, videoMb];
		items = undefined;
		choices = {};
		void loadSummary();
		void loadItems();
	});

	async function trash() {
		working = true;
		try {
			const ids = chosen.map((item) => item.id);
			for (let at = 0; at < ids.length; at += 1000) {
				await api.bulk(ids.slice(at, at + 1000), 'delete');
			}
			confirming = false;
			showToast('ok', t('cleanup.movedToTheTrash'));
			choices = {};
			await Promise.all([loadSummary(), loadItems()]);
		} catch {
			showToast('err', t('common.theActionFailed'));
		} finally {
			working = false;
		}
	}

	async function keep() {
		working = true;
		try {
			await api.keepFromCleanup(chosen.map((item) => item.id));
			showToast('ok', t('cleanup.keptTheyWillNotBe'));
			choices = {};
			await Promise.all([loadSummary(), loadItems()]);
		} catch {
			showToast('err', t('common.theActionFailed'));
		} finally {
			working = false;
		}
	}

	const countOf = (id: CleanupCategoryId) => summary?.categories.find((c) => c.id === id);
</script>

<svelte:head><title>{t('cleanup.cleanUp')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t('cleanup.cleanUp')}</h1></div></div>

{#if failed}
	<Alert kind="err">{t('cleanup.cleanUpCouldNotBe')}</Alert>
{/if}
{#if summary && summary.pending > 0}
	<Alert kind="warn"
		>{t('cleanup.stillBeingAnalysedSummaryPhotos', {
			summary: summary.pending.toLocaleString(dateLocale())
		})}</Alert
	>
{/if}

<div class="cln-cats" role="tablist" aria-label={t('cleanup.kinds')}>
	{#each CATEGORIES as id (id)}
		<button
			type="button"
			role="tab"
			class="cln-cat"
			aria-selected={category === id}
			class:on={category === id}
			onclick={() => (category = id)}
		>
			<span>{titleOf(id)}</span>
			{#if countOf(id)}
				<b>{countOf(id)?.count.toLocaleString(dateLocale())}</b>
				<small>{formatBytes(countOf(id)?.bytes ?? 0)}</small>
			{:else}
				<span class="cln-wait"></span>
			{/if}
		</button>
	{/each}
</div>

<section class="card glass cln">
	<div class="card-b">
		<div class="cln-bar">
			<p>{hintOf(category)}</p>
			{#if category === 'blurry'}
				<label class="cln-ctl">
					<span>{t('cleanup.stricter')}</span>
					<input
						type="range"
						min="1"
						max="5"
						step="1"
						bind:value={blur}
						aria-label={t('cleanup.howStrict')}
					/>
					<span>{t('cleanup.more')}</span>
				</label>
			{:else if category === 'largeVideos'}
				<label class="cln-ctl">
					<span>{t('cleanup.largerThan')}</span>
					<select class="in" bind:value={videoMb}>
						{#each VIDEO_SIZES as size (size)}
							<option value={size}>{size >= 1000 ? `${size / 1000} GB` : `${size} MB`}</option>
						{/each}
					</select>
				</label>
			{/if}
		</div>

		{#if !items}
			<Skeleton height="220px" />
		{:else if items.length === 0}
			<EmptyState icon="check" text={t('cleanup.nothingToCleanUpHere')} />
		{:else}
			<div class="cln-grid">
				{#each items as item (item.id)}
					<div class="cln-item" class:on={isTicked(item)}>
						<button
							type="button"
							class="cln-pick"
							aria-pressed={isTicked(item)}
							aria-label={item.originalName}
							onclick={() => (choices[item.id] = !isTicked(item))}
						>
							<img src="/api/assets/{item.id}/thumbnail" alt="" loading="lazy" />
							<span class="cln-check" aria-hidden="true"
								>{#if isTicked(item)}<Icon name="check" size={14} />{/if}</span
							>
							{#if item.favorite || item.inAlbum}
								<span class="cln-tags">
									{#if item.favorite}<i>{t('common.favorite')}</i>{/if}
									{#if item.inAlbum}<i>{t('cleanup.inAnAlbum')}</i>{/if}
								</span>
							{/if}
						</button>
						<span class="cln-meta">
							{[formatBytes(item.sizeBytes), item.durationMs ? lengthOf(item.durationMs) : '']
								.filter(Boolean)
								.join(' · ')}
						</span>
						{#if item.kind === 'video'}
							<button type="button" class="cln-play" onclick={() => (playing = item)}
								><Icon name="play" size={14} />{t('cleanup.watch')}</button
							>
						{/if}
					</div>
				{/each}
			</div>
			{#if nextOffset !== undefined}
				<div class="cln-more">
					<Button onclick={() => loadItems(true)}>{t('cleanup.showMore')}</Button>
				</div>
			{/if}
		{/if}
	</div>
</section>

{#if items && items.length > 0}
	<div class="cln-act" aria-live="polite">
		<span
			>{t('cleanup.chosencountSelectedFormatbytes', {
				chosenCount: chosen.length,
				formatBytes: formatBytes(chosenBytes)
			})}</span
		>
		<Button disabled={chosen.length === 0 || working} onclick={keep}
			>{t('cleanup.keepTheSelected')}</Button
		>
		<Button
			variant="danger"
			disabled={chosen.length === 0 || working}
			onclick={() => (confirming = true)}
			>{t('cleanup.moveToTheTrashChosencount', {
				chosenCount: chosen.length,
				formatBytes: formatBytes(chosenBytes)
			})}</Button
		>
	</div>
{/if}

<Dialog title={t('cleanup.moveToTheTrash')} bind:open={confirming}>
	<p>
		{t('cleanup.chosencountItemsStayInThe', { chosenCount: chosen.length, trashDays: trashDays() })}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirming = false)}>{t('common.cancel')}</Button>
		<Button variant="danger" disabled={working} onclick={trash}>{t('cleanup.move')}</Button>
	{/snippet}
</Dialog>

<Dialog
	title={playing?.originalName ?? ''}
	bind:open={() => playing !== undefined, (open) => !open && (playing = undefined)}
>
	{#if playing}
		<div class="cln-video">
			<VideoPlayer
				assetId={playing.id}
				sources={{
					hls: `/api/assets/${playing.id}/video/master.m3u8`,
					direct: `/api/assets/${playing.id}/original`
				}}
				autoplay
				onFailed={() => undefined}
			/>
		</div>
	{/if}
</Dialog>
