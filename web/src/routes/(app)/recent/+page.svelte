<script lang="ts">
	import { api } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
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
					? t('recent.addedToFavoritesChanged', { changed })
					: t('recent.archivedChanged', { changed })
			);
			clear();
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
			{t('recent.byWhenItReachedThe')}
		</p>
	</div>
</div>

<CollectionView bind:this={view} scope="recent" {item}>
	{#snippet selectionActions(ids, clear)}
		<button
			type="button"
			class="icon-btn"
			aria-label={t('recent.addToFavorites')}
			title={t('recent.addToFavorites')}
			onclick={() => act(ids, clear, 'favorite')}><Icon name="star" /></button
		>
		<button
			type="button"
			class="icon-btn"
			aria-label={t('recent.archive')}
			title={t('recent.archive')}
			onclick={() => act(ids, clear, 'archive')}><Icon name="archive" /></button
		>
	{/snippet}
</CollectionView>
