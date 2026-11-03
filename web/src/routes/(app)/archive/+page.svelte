<script lang="ts">
	import { api } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import CollectionView from '#lib/organize/CollectionView.svelte';

	const item = appNav.find((candidate) => candidate.path === '/archive') ?? appNav[0];
	let view = $state<CollectionView>();

	async function unarchive(ids: string[], clear: () => void) {
		try {
			const { changed } = await api.bulk(ids, 'unarchive');
			showToast('ok', tr(`Vraćeno u Fotke: ${changed}`, `Back in Photos: ${changed}`));
			clear();
			await view?.reload();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr(item.hr, item.en)}</h1></div></div>

<CollectionView bind:this={view} scope="archive" {item}>
	{#snippet selectionActions(ids, clear)}
		<button
			type="button"
			class="icon-btn"
			aria-label={tr('Vrati u Fotke', 'Back to Photos')}
			title={tr('Vrati u Fotke', 'Back to Photos')}
			onclick={() => unarchive(ids, clear)}><Icon name="archive" /></button
		>
	{/snippet}
</CollectionView>
