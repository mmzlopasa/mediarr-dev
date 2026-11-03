<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, tagSource, type Tag } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const id = $derived(page.params.id ?? '');
	let tag = $state<Tag>();
	let gone = $state(false);
	let timeline = $state<Timeline>();

	onMount(async () => {
		try {
			tag = (await api.tags()).find((candidate) => candidate.id === id);
			gone = !tag;
		} catch {
			gone = true;
		}
	});

	async function untag(ids: string[], clear: () => void) {
		if (!tag) return;
		try {
			const { changed } = await api.changeTag(ids, tag.name, true);
			showToast('ok', tr(`Oznaka uklonjena: ${changed}`, `Tag removed: ${changed}`));
			clear();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tag?.name ?? tr('Oznaka', 'Tag')} — Mediarr</title></svelte:head>

{#if gone}
	<Alert kind="err">{tr('Ova oznaka ne postoji.', 'This tag does not exist.')}</Alert>
{:else if !tag}
	<Skeleton height="220px" />
{:else}
	<div class="ph"><div><h1>{tag.name}</h1></div></div>
	<Timeline
		bind:this={timeline}
		source={tagSource(id)}
		hrefFor={(photo) => resolve('/(app)/photos/[id]', { id: photo })}
		onOpen={(photo) => pushState('', { viewer: photo })}
	>
		{#snippet selectionActions(ids, clear)}
			<button
				type="button"
				class="icon-btn"
				aria-label={tr('Ukloni oznaku', 'Remove the tag')}
				title={tr('Ukloni oznaku', 'Remove the tag')}
				onclick={() => untag(ids, clear)}><Icon name="list" /></button
			>
		{/snippet}
	</Timeline>
	{#if page.state.viewer}
		<Viewer
			id={page.state.viewer}
			onClose={() => history.back()}
			onNavigate={(photo) => replaceState('', { viewer: photo })}
			onChanged={() => timeline?.reloadLoaded()}
			neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
		/>
	{/if}
{/if}
