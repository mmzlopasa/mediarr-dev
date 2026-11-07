<script lang="ts">
	import { resolve } from '$app/paths';
	import type { Album } from '#lib/api.ts';
	import Badge from '#lib/design/components/Badge.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let { album }: { album: Album } = $props();
	const inside = $derived(album.childCount ?? 0);
</script>

<a class="alb-card" href={resolve('/(app)/albums/[id]', { id: album.id })} data-album={album.title}>
	<span class="alb-cover">
		{#if album.coverAssetId}
			<img src="/api/assets/{album.coverAssetId}/thumbnail" alt="" loading="lazy" />
		{:else}
			<Icon name="album" size={32} />
		{/if}
		{#if inside}
			<span class="alb-inside" title={tr('Albumi unutra', 'Albums inside')}
				><Icon name="folder" size={12} />{inside}</span
			>
		{/if}
	</span>
	<span class="alb-name">{album.title}</span>
	<span class="alb-meta">
		{album.assetCount}
		{#if inside}· {inside === 1
				? tr('1 album', '1 album')
				: tr(`${inside} albuma`, `${inside} albums`)}{/if}
		{#if album.isSmart}· <Badge kind="acc">{tr('Pametni', 'Smart')}</Badge>{/if}
		{#if album.role !== 'owner'}· {album.ownerName}{/if}
	</span>
</a>
