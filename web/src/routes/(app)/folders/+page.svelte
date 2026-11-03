<script lang="ts">
	import { goto, pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { api, type Folder } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const current = $derived(page.url.searchParams.get('path') ?? '');
	const parts = $derived(current ? current.split('/') : []);

	let data = $state<Folder>();
	let failed = $state(false);

	async function load(path: string) {
		try {
			const loaded = await api.folder(path);
			if (path === current) {
				data = loaded;
				failed = false;
			}
		} catch {
			failed = true;
		}
	}

	$effect(() => {
		data = undefined;
		load(current);
	});

	function open(path: string) {
		// A plain path built here, so this stays a link inside the same page.
		// eslint-disable-next-line svelte/no-navigation-without-resolve
		goto(path ? `?path=${encodeURIComponent(path)}` : '?');
	}

	const join = (name: string) => (current ? `${current}/${name}` : name);

	function neighbours(id: string) {
		const items = data?.items ?? [];
		const index = items.findIndex((item) => item.id === id);
		return { newer: items[index - 1]?.id, older: items[index + 1]?.id };
	}
</script>

<svelte:head><title>{tr('Mape', 'Folders')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr('Mape', 'Folders')}</h1>
		{#if parts.length}
			<nav class="folder-path" aria-label={tr('Putanja', 'Path')}>
				<button type="button" onclick={() => open('')}>{tr('Vrh', 'Top')}</button>
				{#each parts as part, index (index)}
					<span>/</span>
					<button type="button" onclick={() => open(parts.slice(0, index + 1).join('/'))}
						>{part}</button
					>
				{/each}
			</nav>
		{/if}
	</div>
</div>

{#if failed}
	<Alert kind="err">{tr('Mapa se nije učitala.', 'The folder could not be loaded.')}</Alert>
{:else if !data}
	<Skeleton height="200px" />
{:else if !data.available}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon="folder"
				text={tr(
					'Nemate vanjsku biblioteku. Administrator je postavlja u Postavkama.',
					'You have no external library. An administrator sets it up in Settings.'
				)}
			/>
		</div>
	</section>
{:else if data.folders.length === 0 && data.items.length === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState icon="folder" text={tr('Ova mapa je prazna.', 'This folder is empty.')} />
		</div>
	</section>
{:else}
	<div class="folder-grid">
		{#each data.folders as folder (folder.name)}
			<button type="button" class="folder-tile" onclick={() => open(join(folder.name))}>
				<img src="/api/assets/{folder.coverId}/thumbnail" alt="" />
				<b>{folder.name}</b>
				<small>{folder.count}</small>
			</button>
		{/each}
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
		onChanged={() => load(current)}
	/>
{/if}
