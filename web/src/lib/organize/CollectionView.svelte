<script lang="ts">
	import type { Snippet } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { collectionBase, collectionSource } from '#lib/api.ts';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const POLL_MS = 10000;

	let {
		scope,
		item,
		selectionActions
	}: {
		scope: 'favorites' | 'archive' | 'trash' | 'vault' | 'recent';
		item: NavItem;
		selectionActions: Snippet<[string[], () => void]>;
	} = $props();

	let timeline = $state<Timeline>();
	let total = $state<number>();

	export function reload() {
		return timeline?.reloadLoaded();
	}

	$effect(() => {
		const timer = setInterval(() => timeline?.refresh(), POLL_MS);
		return () => clearInterval(timer);
	});
</script>

{#if total === 0}
	<section class="card glass">
		<div class="card-b"><EmptyState icon={item.icon} text={item.empty ? t(item.empty) : ''} /></div>
	</section>
{/if}

<Timeline
	bind:this={timeline}
	source={collectionSource(scope)}
	base={collectionBase(scope)}
	ownActions={false}
	downloads={false}
	{selectionActions}
	hrefFor={() => page.url.pathname}
	onOpen={(photo) => pushState('', { viewer: photo })}
	onCount={(count) => (total = count)}
/>

{#if page.state.viewer}
	<Viewer
		id={page.state.viewer}
		base={collectionBase(scope)}
		onClose={() => history.back()}
		onNavigate={(photo) => replaceState('', { viewer: photo })}
		onChanged={() => timeline?.reloadLoaded()}
		neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
		strip={(photo) => timeline?.around(photo) ?? []}
		playlist={(photo) => timeline?.playlist(photo) ?? Promise.resolve([])}
	/>
{/if}
