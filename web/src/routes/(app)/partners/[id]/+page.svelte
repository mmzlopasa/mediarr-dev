<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, partnerSource, type PartnerEntry } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const POLL_MS = 10000;

	const id = $derived(page.params.id ?? '');
	const source = $derived(partnerSource(id));
	let partner = $state<PartnerEntry>();
	let gone = $state(false);
	let timeline = $state<Timeline>();

	async function load() {
		try {
			const { received } = await api.partners();
			partner = received.find((entry) => entry.userId === id);
			gone = !partner;
			await timeline?.refresh();
		} catch {
			gone = true;
		}
	}

	onMount(() => {
		const photo = page.url.searchParams.get('photo');
		if (photo) pushState('', { viewer: photo });
	});

	$effect(() => {
		void id;
		load();
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});
</script>

<svelte:head><title>{partner?.name ?? t('partners.id.partner')} — Mediarr</title></svelte:head>

{#if gone}
	<Alert kind="err">
		{t('partners.id.thisLibraryIsNotShared')}
		<a href={resolve('/(app)/shared')}>{t('partners.id.back')}</a>
	</Alert>
{:else if !partner}
	<Skeleton height="220px" />
{:else}
	<div class="ph"><div><h1>{partner.name}</h1></div></div>
	<Timeline
		bind:this={timeline}
		{source}
		selectable={false}
		ownActions={false}
		hrefFor={(photo) => `${resolve('/(app)/partners/[id]', { id })}?photo=${photo}`}
		onOpen={(photo) => pushState('', { viewer: photo })}
	/>
	{#if page.state.viewer}
		<Viewer
			id={page.state.viewer}
			onClose={() => history.back()}
			onNavigate={(photo) => replaceState('', { viewer: photo })}
			onChanged={() => {}}
			neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
			strip={(photo) => timeline?.around(photo) ?? []}
			playlist={(photo) => timeline?.playlist(photo) ?? Promise.resolve([])}
		/>
	{/if}
{/if}
