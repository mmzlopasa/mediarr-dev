<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { api, type Documents } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import Viewer from '#lib/timeline/Viewer.svelte';

	let data = $state<Documents>();
	let failed = $state(false);

	async function load() {
		try {
			data = await api.documents();
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(load);

	function neighbours(id: string) {
		const items = data?.items ?? [];
		const index = items.findIndex((item) => item.id === id);
		return { newer: items[index - 1]?.id, older: items[index + 1]?.id };
	}
</script>

<svelte:head><title>{tr('Dokumenti', 'Documents')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr('Dokumenti', 'Documents')}</h1></div></div>

{#if failed}
	<Alert kind="err">{tr('Dokumenti se nisu učitali.', 'Documents could not be loaded.')}</Alert>
{:else if !data}
	<Skeleton height="200px" />
{:else if !data.enabled || !data.analysisOn || data.items.length === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon="list"
				text={!data.enabled
					? tr(
							'Administrator nije uključio ovaj album.',
							'An administrator has not turned this album on.'
						)
					: !data.analysisOn
						? tr('Za ovo treba uključiti analizu slika.', 'This needs picture analysis to be on.')
						: tr('Još nema fotki s tekstom.', 'No photos with text yet.')}
			/>
		</div>
	</section>
{:else}
	<div class="folder-grid">
		{#each data.items as item (item.id)}
			<button
				type="button"
				class="folder-tile folder-photo"
				aria-label={tr('Otvori', 'Open')}
				onclick={() => pushState('', { viewer: item.id })}
			>
				<img src="/api/assets/{item.id}/thumbnail" alt="" />
			</button>
		{/each}
	</div>
{/if}

{#if page.state.viewer}
	<Viewer
		id={page.state.viewer}
		{neighbours}
		onClose={() => history.back()}
		onNavigate={(photo) => replaceState('', { viewer: photo })}
		onChanged={load}
	/>
{/if}
