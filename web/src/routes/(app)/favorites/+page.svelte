<script lang="ts">
	import { api } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import CollectionView from '#lib/organize/CollectionView.svelte';

	const item = appNav.find((candidate) => candidate.path === '/favorites') ?? appNav[0];
	let view = $state<CollectionView>();

	async function unfavorite(ids: string[], clear: () => void) {
		try {
			const { changed } = await api.bulk(ids, 'unfavorite');
			showToast('ok', t('favorites.removedFromFavoritesChanged', { changed }));
			clear();
			await view?.reload();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t(item.label)}</h1></div></div>

<CollectionView bind:this={view} scope="favorites" {item}>
	{#snippet selectionActions(ids, clear)}
		<button
			type="button"
			class="icon-btn"
			aria-label={t('favorites.removeFromFavorites')}
			title={t('favorites.removeFromFavorites')}
			onclick={() => unfavorite(ids, clear)}><Icon name="star" /></button
		>
	{/snippet}
</CollectionView>
