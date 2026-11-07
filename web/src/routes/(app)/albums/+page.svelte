<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type Album, type AlbumRules } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Checkbox from '#lib/design/components/Checkbox.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import AlbumCard from '#lib/albums/AlbumCard.svelte';
	import RulesForm from '#lib/albums/RulesForm.svelte';
	import { appNav } from '#lib/nav.ts';

	const POLL_MS = 10000;
	const item = appNav.find((candidate) => candidate.path === '/albums') ?? appNav[0];

	let albums = $state<Album[]>();
	let failed = $state(false);
	let sort = $state<'updated' | 'title' | 'date'>('updated');
	let creating = $state(false);
	let title = $state('');
	let description = $state('');
	let smart = $state(false);
	let rules = $state<AlbumRules>({});
	let busy = $state(false);
	// Albums inside others are on the page of the one they are in.
	const top = $derived(albums?.filter((album) => !album.parentId));

	async function load() {
		try {
			albums = await api.albums(sort);
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(() => {
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	$effect(() => {
		void sort;
		load();
	});

	async function create(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		try {
			await api.createAlbum({ title, description, rules: smart ? rules : undefined });
			creating = false;
			title = description = '';
			smart = false;
			await load();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error
					? cause.message
					: tr('Album nije stvoren.', 'The album was not created.')
			);
		} finally {
			busy = false;
		}
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
	<div class="ph-a">
		<Select
			inline
			label={tr('Poredak', 'Sort')}
			bind:value={sort}
			options={[
				{ value: 'updated', label: tr('Zadnja promjena', 'Last change') },
				{ value: 'title', label: tr('Naziv', 'Name') },
				{ value: 'date', label: tr('Datum fotki', 'Photo date') }
			]}
		/>
		<Button small href={resolve('/(app)/tags')}
			><Icon name="tag" size={15} />{tr('Oznake', 'Tags')}</Button
		>
		<Button small variant="gold" onclick={() => (creating = true)}>
			<Icon name="plus" size={15} />
			{tr('Novi album', 'New album')}
		</Button>
	</div>
</div>

{#if failed}
	<Alert kind="err">{tr('Albumi se nisu učitali.', 'Albums could not be loaded.')}</Alert>
{/if}

{#if !albums && !failed}
	<div class="alb-grid" aria-hidden="true">
		<Skeleton height="220px" /><Skeleton height="220px" /><Skeleton height="220px" />
	</div>
{:else if top?.length === 0}
	<section class="card glass">
		<div class="card-b"><EmptyState icon={item.icon} text={tr(item.emptyHr, item.emptyEn)} /></div>
	</section>
{:else if top}
	<div class="alb-grid">
		{#each top as album (album.id)}
			<AlbumCard {album} />
		{/each}
	</div>
{/if}

<Dialog title={tr('Novi album', 'New album')} bind:open={creating}>
	<form id="new-album" class="form" onsubmit={create}>
		<Input label={tr('Naziv', 'Name')} required maxlength={200} bind:value={title} />
		<Input label={tr('Opis', 'Description')} bind:value={description} />
		<Checkbox
			label={tr('Pametni album: puni se sam po pravilima', 'Smart album: fills itself from rules')}
			bind:checked={smart}
		/>
		{#if smart}<RulesForm bind:rules />{/if}
	</form>
	{#snippet footer()}
		<Button onclick={() => (creating = false)}>{tr('Odustani', 'Cancel')}</Button>
		<Button type="submit" form="new-album" variant="gold" disabled={busy || !title.trim()}
			>{tr('Stvori', 'Create')}</Button
		>
	{/snippet}
</Dialog>
