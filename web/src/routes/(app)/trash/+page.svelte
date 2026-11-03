<script lang="ts">
	import { api } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
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
			showToast('ok', tr(`Vraćeno: ${changed}`, `Restored: ${changed}`));
			clear();
			await view?.reload();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function purge() {
		if (!toPurge) return;
		try {
			const { changed } = await api.bulk(toPurge.ids, 'purge');
			showToast('ok', tr(`Trajno obrisano: ${changed}`, `Permanently deleted: ${changed}`));
			toPurge.clear();
			confirmPurge = false;
			await view?.reload();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function empty() {
		try {
			const { changed } = await api.emptyTrash();
			showToast('ok', tr(`Trajno obrisano: ${changed}`, `Permanently deleted: ${changed}`));
			confirmEmpty = false;
			await view?.reload();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr(item.hr, item.en)}</h1>
		<p>
			{tr('Stavke se trajno brišu nakon 30 dana.', 'Items are permanently deleted after 30 days.')}
		</p>
	</div>
	<div class="ph-a">
		<Button small variant="danger" onclick={() => (confirmEmpty = true)}
			>{tr('Isprazni smeće', 'Empty the trash')}</Button
		>
	</div>
</div>

<CollectionView bind:this={view} scope="trash" {item}>
	{#snippet selectionActions(ids, clear)}
		<button
			type="button"
			class="icon-btn"
			aria-label={tr('Vrati', 'Restore')}
			title={tr('Vrati', 'Restore')}
			onclick={() => restore(ids, clear)}><Icon name="sync" /></button
		>
		<button
			type="button"
			class="icon-btn"
			aria-label={tr('Obriši trajno', 'Delete permanently')}
			title={tr('Obriši trajno', 'Delete permanently')}
			onclick={() => {
				toPurge = { ids, clear };
				confirmPurge = true;
			}}><Icon name="trash" /></button
		>
	{/snippet}
</CollectionView>

<Dialog title={tr('Obrisati trajno?', 'Delete permanently?')} bind:open={confirmPurge}>
	<p>
		{tr(
			'Originali se brišu s diska. To se ne može poništiti.',
			'The originals are removed from the disk. This cannot be undone.'
		)}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmPurge = false)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" onclick={purge}>{tr('Obriši trajno', 'Delete permanently')}</Button>
	{/snippet}
</Dialog>

<Dialog title={tr('Isprazniti smeće?', 'Empty the trash?')} bind:open={confirmEmpty}>
	<p>
		{tr(
			'Svi originali iz smeća brišu se s diska. To se ne može poništiti.',
			'All originals in the trash are removed from the disk. This cannot be undone.'
		)}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmEmpty = false)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" onclick={empty}>{tr('Isprazni smeće', 'Empty the trash')}</Button>
	{/snippet}
</Dialog>
