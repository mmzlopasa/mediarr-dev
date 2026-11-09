<script lang="ts">
	import { api, formatBytes, type TrashSummary } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import CollectionView from '#lib/organize/CollectionView.svelte';

	const item = appNav.find((candidate) => candidate.path === '/trash') ?? appNav[0];
	let view = $state<CollectionView>();
	let confirmEmpty = $state(false);
	let toPurge = $state<{ ids: string[]; clear: () => void }>();
	let confirmPurge = $state(false);

	async function restore(ids: string[], clear: () => void) {
		try {
			const { changed } = await api.bulk(ids, 'restore');
			showToast('ok', t('trash.restoredChanged', { changed }));
			clear();
			await view?.reload();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function purge() {
		if (!toPurge) return;
		try {
			const { changed } = await api.bulk(toPurge.ids, 'purge');
			showToast('ok', t('trash.permanentlyDeletedChanged', { changed }));
			toPurge.clear();
			confirmPurge = false;
			await view?.reload();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	let summary = $state<TrashSummary>();

	// What it would remove is shown before anything is decided.
	$effect(() => {
		if (!confirmEmpty) return;
		api
			.trashSummary()
			.then((value) => (summary = value))
			.catch(() => (summary = undefined));
	});

	async function empty() {
		try {
			const { changed } = await api.emptyTrash();
			showToast('ok', t('trash.permanentlyDeletedChanged', { changed }));
			confirmEmpty = false;
			await view?.reload();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t(item.label)}</h1>
		<p>
			{t('trash.itemsArePermanentlyDeletedAfter')}
		</p>
	</div>
	<div class="ph-a">
		<Button small variant="danger" onclick={() => (confirmEmpty = true)}
			>{t('trash.emptyTheTrash')}</Button
		>
	</div>
</div>

<CollectionView bind:this={view} scope="trash" {item}>
	{#snippet selectionActions(ids, clear)}
		<button
			type="button"
			class="icon-btn"
			aria-label={t('trash.restore')}
			title={t('trash.restore')}
			onclick={() => restore(ids, clear)}><Icon name="sync" /></button
		>
		<button
			type="button"
			class="icon-btn"
			aria-label={t('trash.deletePermanently')}
			title={t('trash.deletePermanently')}
			onclick={() => {
				toPurge = { ids, clear };
				confirmPurge = true;
			}}><Icon name="trash" /></button
		>
	{/snippet}
</CollectionView>

<Dialog title={t('trash.deletePermanently2')} bind:open={confirmPurge}>
	<p>
		{t('trash.theOriginalsAreRemovedFrom')}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmPurge = false)}>{t('common.cancel')}</Button>
		<Button variant="danger" onclick={purge}>{t('trash.deletePermanently')}</Button>
	{/snippet}
</Dialog>

<Dialog title={t('trash.emptyTheTrash2')} bind:open={confirmEmpty}>
	<p>
		{t('trash.allOriginalsInTheTrash')}
	</p>
	{#if summary}
		<p data-testid="trash-summary">
			{t('trash.thisRemovesAssetsFilesFormatbytes', {
				assets: summary.assets,
				formatBytes: formatBytes(summary.bytes)
			})}
		</p>
	{/if}
	{#snippet footer()}
		<Button onclick={() => (confirmEmpty = false)}>{t('common.cancel')}</Button>
		<Button variant="danger" onclick={empty}>{t('trash.emptyTheTrash')}</Button>
	{/snippet}
</Dialog>
