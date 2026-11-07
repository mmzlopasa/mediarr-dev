<script lang="ts">
	import { api } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import CollectionView from '#lib/organize/CollectionView.svelte';

	const item = appNav.find((candidate) => candidate.path === '/recent') ?? appNav[0];
	let view = $state<CollectionView>();

	async function act(ids: string[], clear: () => void, action: 'favorite' | 'archive') {
		try {
			const { changed } = await api.bulk(ids, action);
			showToast(
				'ok',
				action === 'favorite'
					? tr(`Dodano u favorite: ${changed}`, `Added to favorites: ${changed}`)
					: tr(`Arhivirano: ${changed}`, `Archived: ${changed}`)
			);
			clear();
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
			{tr(
				'Po tome kad je stiglo na server, ne kad je snimljeno: ovdje se odmah vidi što je donio backup ili uvoz.',
				'By when it reached the server, not when it was taken: what a backup or an import brought shows here at once.'
			)}
		</p>
	</div>
</div>

<CollectionView bind:this={view} scope="recent" {item}>
	{#snippet selectionActions(ids, clear)}
		<button
			type="button"
			class="icon-btn"
			aria-label={tr('Dodaj u favorite', 'Add to favorites')}
			title={tr('Dodaj u favorite', 'Add to favorites')}
			onclick={() => act(ids, clear, 'favorite')}><Icon name="star" /></button
		>
		<button
			type="button"
			class="icon-btn"
			aria-label={tr('Arhiviraj', 'Archive')}
			title={tr('Arhiviraj', 'Archive')}
			onclick={() => act(ids, clear, 'archive')}><Icon name="archive" /></button
		>
	{/snippet}
</CollectionView>
