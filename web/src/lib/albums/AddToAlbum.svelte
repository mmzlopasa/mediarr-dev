<script lang="ts">
	import { api, type Album } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let { ids, onDone }: { ids: string[]; onDone: () => void } = $props();

	let open = $state(false);
	let albums = $state<Album[]>();
	let failed = $state(false);
	let title = $state('');
	let busy = $state(false);

	async function show() {
		open = true;
		albums = undefined;
		failed = false;
		try {
			const all = await api.albums('title');
			albums = all.filter((album) => !album.isSmart && album.role !== 'viewer');
		} catch {
			failed = true;
		}
	}

	async function add(id: string, name: string) {
		busy = true;
		try {
			const { changed } = await api.addToAlbum(id, ids);
			showToast('ok', tr(`Dodano u „${name}”: ${changed}`, `Added to "${name}": ${changed}`));
			open = false;
			onDone();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		} finally {
			busy = false;
		}
	}

	async function create(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		try {
			const album = await api.createAlbum({ title });
			await add(album.id, album.title);
			title = '';
		} catch {
			showToast('err', tr('Album nije stvoren.', 'The album was not created.'));
		} finally {
			busy = false;
		}
	}
</script>

<button
	type="button"
	class="icon-btn"
	aria-label={tr('Dodaj u album', 'Add to album')}
	title={tr('Dodaj u album', 'Add to album')}
	onclick={show}><Icon name="album" /></button
>

<Dialog title={tr('Dodaj u album', 'Add to album')} bind:open>
	{#if failed}
		<Alert kind="err">{tr('Albumi se nisu učitali.', 'Albums could not be loaded.')}</Alert>
	{:else if !albums}
		<Skeleton height="60px" />
	{:else}
		{#each albums as album (album.id)}
			<div class="alb-list">
				<b>{album.title}</b>
				<Button small disabled={busy} onclick={() => add(album.id, album.title)}
					>{tr('Dodaj', 'Add')}</Button
				>
			</div>
		{/each}
	{/if}
	<form class="form" onsubmit={create}>
		<Input label={tr('Novi album', 'New album')} bind:value={title} maxlength={200} />
		<Button type="submit" small disabled={busy || !title.trim()}
			>{tr('Stvori i dodaj', 'Create and add')}</Button
		>
	</form>
</Dialog>
