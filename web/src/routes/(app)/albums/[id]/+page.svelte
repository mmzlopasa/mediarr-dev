<script lang="ts">
	import { parallax } from '#lib/motion/actions.ts';
	import { onMount } from 'svelte';
	import { goto, pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { albumSource, api, type Album, type AlbumRules } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import UploadButton from '#lib/design/components/UploadButton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import LinksDialog from '#lib/albums/LinksDialog.svelte';
	import RulesForm from '#lib/albums/RulesForm.svelte';
	import ShareDialog from '#lib/albums/ShareDialog.svelte';
	import AlbumActivity from '#lib/timeline/AlbumActivity.svelte';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const POLL_MS = 10000;

	let id = $derived(page.params.id ?? '');
	let album = $state<Album>();
	let gone = $state(false);
	let timeline = $state<Timeline>();
	let sharing = $state(false);
	let linking = $state(false);
	let editing = $state(false);
	let confirmDelete = $state(false);
	let showComments = $state(false);

	let title = $state('');
	let description = $state('');
	let order = $state<Album['order']>('newest');
	let rules = $state<AlbumRules>({});

	const source = $derived(albumSource(id));
	const role = $derived(album?.role);
	const canAdd = $derived(!album?.isSmart && role !== 'viewer');
	const canEdit = $derived(role === 'owner' || role === 'editor');
	const isOwner = $derived(role === 'owner');

	const roleLabels = $derived({
		owner: tr('Vlasnik', 'Owner'),
		editor: tr('Urednik', 'Editor'),
		contributor: tr('Suradnik', 'Contributor'),
		viewer: tr('Gledatelj', 'Viewer')
	});

	async function load() {
		try {
			const next = await api.album(id);
			const changed = album && next.updatedAt !== album.updatedAt;
			album = next;
			gone = false;
			// What other people did shows up without reloading the page.
			if (changed) await timeline?.reloadLoaded();
			else await timeline?.refresh();
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

	function startEdit() {
		if (!album) return;
		title = album.title;
		description = album.description;
		order = album.order;
		rules = album.rules ?? {};
		editing = true;
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		try {
			album = await api.updateAlbum(id, {
				title,
				description,
				order,
				rules: album?.isSmart ? rules : undefined
			});
			editing = false;
			await timeline?.reloadLoaded();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	async function remove() {
		try {
			await api.deleteAlbum(id);
			await goto(resolve('/(app)/albums'));
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function leave() {
		const me = page.data.user?.id;
		if (!me) return;
		try {
			await api.removeMember(id, me);
			await goto(resolve('/(app)/albums'));
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function removeSelected(ids: string[], clear: () => void) {
		try {
			const { changed } = await api.removeFromAlbum(id, ids);
			showToast(
				changed === ids.length ? 'ok' : 'warn',
				changed === ids.length
					? tr(`Uklonjeno iz albuma: ${changed}`, `Removed from the album: ${changed}`)
					: tr(
							`Uklonjeno: ${changed} od ${ids.length}. Možete ukloniti samo fotke koje ste sami dodali.`,
							`Removed: ${changed} of ${ids.length}. You can remove only photos you added yourself.`
						)
			);
			clear();
			await load();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function setCover(assetId: string, clear: () => void) {
		try {
			album = await api.updateAlbum(id, { coverAssetId: assetId });
			showToast('ok', tr('Naslovnica je postavljena.', 'The cover is set.'));
			clear();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	function open(photo: string) {
		pushState('', { viewer: photo });
	}
</script>

<svelte:head><title>{album?.title ?? tr('Album', 'Album')} — Mediarr</title></svelte:head>

{#if gone && !album}
	<Alert kind="err">{tr('Ovaj album nije dostupan.', 'This album is not available.')}</Alert>
{:else if !album}
	<div class="form" aria-hidden="true">
		<Skeleton height="44px" width="40%" /><Skeleton height="220px" />
	</div>
{:else}
	{#if album.coverAssetId}
		<div class="alb-hero">
			<img
				use:parallax
				src="/api/assets/{album.coverAssetId}/thumbnail?size=large"
				alt=""
				decoding="async"
			/>
		</div>
	{/if}
	<div class="ph">
		<div>
			<h1>{album.title}</h1>
			<p>
				{album.assetCount} ·
				{#if album.isSmart}<Badge kind="acc">{tr('Pametni', 'Smart')}</Badge> ·{/if}
				{roleLabels[album.role]}{#if !isOwner}
					· {album.ownerName}{/if}
			</p>
			{#if album.description}<p>{album.description}</p>{/if}
		</div>
		<div class="ph-a">
			{#if canAdd}
				<UploadButton albumId={id} />
			{/if}
			<Button small onclick={() => (showComments = !showComments)}>
				<Icon name="comment" size={14} />
				{tr('Komentari', 'Comments')}
			</Button>
			{#if isOwner}
				<Button small onclick={() => (sharing = true)}>
					<Icon name="users" size={14} />
					{tr('Dijeli', 'Share')}
				</Button>
				<Button small onclick={() => (linking = true)}>
					<Icon name="share" size={14} />
					{tr('Linkovi', 'Links')}
				</Button>
			{/if}
			{#if canEdit}
				<Button small onclick={startEdit}>{tr('Uredi', 'Edit')}</Button>
			{/if}
			{#if isOwner}
				<Button small variant="danger" onclick={() => (confirmDelete = true)}
					>{tr('Obriši', 'Delete')}</Button
				>
			{:else}
				<Button small onclick={leave}>{tr('Napusti', 'Leave')}</Button>
			{/if}
		</div>
	</div>

	{#if gone}
		<Alert kind="warn"
			>{tr('Veza s albumom je prekinuta.', 'The connection to this album was lost.')}</Alert
		>
	{/if}

	{#if showComments}
		<Card title={tr('Komentari', 'Comments')}>
			<AlbumActivity albumId={id} revision={album.updatedAt} />
		</Card>
	{/if}

	{#if album.assetCount === 0}
		<section class="card glass">
			<div class="card-b">
				<EmptyState
					icon="album"
					text={album.isSmart
						? tr('Nijedna fotka ne odgovara pravilima.', 'No photos match the rules.')
						: canAdd
							? tr(
									'Album je prazan. Pošaljite ih ovdje ili ih odaberite među Medijima.',
									'This album is empty. Upload here, or select items under Media.'
								)
							: tr('Album je prazan.', 'This album is empty.')}
				/>
			</div>
		</section>
	{/if}

	<Timeline
		bind:this={timeline}
		{source}
		onOpen={open}
		hrefFor={(photo) => `${resolve('/(app)/albums/[id]', { id })}?photo=${photo}`}
		ownActions={false}
		selectable={canAdd || canEdit}
	>
		{#snippet selectionActions(ids, clear)}
			{#if canEdit && ids.length === 1}
				<button
					type="button"
					class="icon-btn"
					aria-label={tr('Postavi kao naslovnicu', 'Set as cover')}
					title={tr('Postavi kao naslovnicu', 'Set as cover')}
					onclick={() => setCover(ids[0], clear)}><Icon name="photo" /></button
				>
			{/if}
			{#if canAdd}
				<button
					type="button"
					class="icon-btn"
					aria-label={tr('Ukloni iz albuma', 'Remove from album')}
					title={tr('Ukloni iz albuma', 'Remove from album')}
					onclick={() => removeSelected(ids, clear)}><Icon name="trash" /></button
				>
			{/if}
		{/snippet}
	</Timeline>

	{#if page.state.viewer}
		<Viewer
			id={page.state.viewer}
			albumId={id}
			onClose={() => history.back()}
			onNavigate={(photo) => replaceState('', { viewer: photo })}
			onChanged={() => timeline?.reloadLoaded()}
			neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
			strip={(photo) => timeline?.around(photo) ?? []}
		/>
	{/if}

	<ShareDialog {album} bind:open={sharing} onChanged={load} />
	<LinksDialog {album} bind:open={linking} />

	<Dialog title={tr('Uredi album', 'Edit album')} bind:open={editing}>
		<form id="edit-album" class="form" onsubmit={save}>
			<Input label={tr('Naziv', 'Name')} required maxlength={200} bind:value={title} />
			<Input label={tr('Opis', 'Description')} bind:value={description} />
			<Select
				label={tr('Redoslijed', 'Order')}
				bind:value={order}
				options={[
					{ value: 'newest', label: tr('Najnovije prvo', 'Newest first') },
					{ value: 'oldest', label: tr('Najstarije prvo', 'Oldest first') }
				]}
			/>
			{#if album.isSmart}<RulesForm bind:rules />{/if}
		</form>
		{#snippet footer()}
			<Button onclick={() => (editing = false)}>{tr('Odustani', 'Cancel')}</Button>
			<Button type="submit" form="edit-album" variant="gold">{tr('Spremi', 'Save')}</Button>
		{/snippet}
	</Dialog>

	<Dialog title={tr('Obrisati album?', 'Delete this album?')} bind:open={confirmDelete}>
		<p>
			{tr(
				'Fotke ostaju u biblioteci. Javni linkovi prestaju raditi.',
				'The photos stay in the library. Public links stop working.'
			)}
		</p>
		{#snippet footer()}
			<Button onclick={() => (confirmDelete = false)}>{tr('Odustani', 'Cancel')}</Button>
			<Button variant="danger" onclick={remove}>{tr('Obriši', 'Delete')}</Button>
		{/snippet}
	</Dialog>
{/if}
