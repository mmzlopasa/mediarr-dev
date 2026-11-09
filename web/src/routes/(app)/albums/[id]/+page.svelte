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
	import { t } from '#lib/i18n.svelte.ts';
	import LinksDialog from '#lib/albums/LinksDialog.svelte';
	import AlbumCard from '#lib/albums/AlbumCard.svelte';
	import RulesForm from '#lib/albums/RulesForm.svelte';
	import ShareDialog from '#lib/albums/ShareDialog.svelte';
	import AlbumActivity from '#lib/timeline/AlbumActivity.svelte';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Slideshow from '#lib/timeline/Slideshow.svelte';
	import type { SlideItem } from '#lib/timeline/slideshow.ts';
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
	let slides = $state<SlideItem[]>();

	async function startSlideshow() {
		const all = (await timeline?.playlist('')) ?? [];
		if (all.length) slides = all;
	}
	// Every album this user sees: the ones in this one, the one it is in, and where it can move.
	let allAlbums = $state<Album[]>([]);
	let making = $state(false);
	let moving = $state(false);
	let childTitle = $state('');
	let moveTo = $state('');
	const children = $derived(allAlbums.filter((entry) => entry.parentId === id));
	const parent = $derived(allAlbums.find((entry) => entry.id === album?.parentId));
	// Not into itself, nor into an album inside it.
	const inside = $derived.by(() => {
		// eslint-disable-next-line svelte/prefer-svelte-reactivity -- made anew on each change, never changed in place
		const out = new Set([id]);
		let grew = true;
		while (grew) {
			grew = false;
			for (const entry of allAlbums) {
				if (entry.parentId && out.has(entry.parentId) && !out.has(entry.id)) {
					out.add(entry.id);
					grew = true;
				}
			}
		}
		return out;
	});
	const destinations = $derived(
		allAlbums.filter((entry) => entry.role === 'owner' && !entry.isSmart && !inside.has(entry.id))
	);

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
		owner: t('albums.id.owner'),
		editor: t('albums.id.editor'),
		contributor: t('albums.id.contributor'),
		viewer: t('albums.id.viewer')
	});

	async function load() {
		api
			.albums('title')
			.then((found) => (allAlbums = found))
			.catch(() => undefined);
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
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	async function makeChild(event: SubmitEvent) {
		event.preventDefault();
		try {
			await api.createAlbum({ title: childTitle, parentId: id });
			making = false;
			childTitle = '';
			await load();
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theAlbumWasNotCreated'));
		}
	}

	function startMove() {
		moveTo = album?.parentId ?? '';
		moving = true;
	}

	async function move(event: SubmitEvent) {
		event.preventDefault();
		try {
			album = await api.moveAlbum(id, moveTo || null);
			moving = false;
			await load();
			showToast('ok', t('albums.id.theAlbumWasMoved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('albums.id.notMoved'));
		}
	}

	async function remove() {
		try {
			await api.deleteAlbum(id);
			await goto(resolve('/(app)/albums'));
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function leave() {
		const me = page.data.user?.id;
		if (!me) return;
		try {
			await api.removeMember(id, me);
			await goto(resolve('/(app)/albums'));
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function removeSelected(ids: string[], clear: () => void) {
		try {
			const { changed } = await api.removeFromAlbum(id, ids);
			showToast(
				changed === ids.length ? 'ok' : 'warn',
				changed === ids.length
					? t('albums.id.removedFromTheAlbumChanged', { changed })
					: t('albums.id.removedChangedOfIdscountYou', { changed, idsCount: ids.length })
			);
			clear();
			await load();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function setCover(assetId: string, clear: () => void) {
		try {
			album = await api.updateAlbum(id, { coverAssetId: assetId });
			showToast('ok', t('albums.id.theCoverIsSet'));
			clear();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	function open(photo: string) {
		pushState('', { viewer: photo });
	}
</script>

<svelte:head><title>{album?.title ?? t('albums.id.album')} — Mediarr</title></svelte:head>

{#if gone && !album}
	<Alert kind="err">{t('albums.id.thisAlbumIsNotAvailable')}</Alert>
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
			{#if parent}
				<a class="alb-up" href={resolve('/(app)/albums/[id]', { id: parent.id })}
					><Icon name="back" size={13} />{parent.title}</a
				>
			{/if}
			<h1>{album.title}</h1>
			<p>
				{album.assetCount} ·
				{#if album.isSmart}<Badge kind="acc">{t('albums.id.smart')}</Badge> ·{/if}
				{roleLabels[album.role]}{#if !isOwner}
					· {album.ownerName}{/if}
			</p>
			{#if album.description}<p>{album.description}</p>{/if}
		</div>
		<div class="ph-a">
			{#if canAdd}
				<UploadButton albumId={id} />
			{/if}
			{#if album.assetCount > 0}
				<Button small onclick={startSlideshow}>
					<Icon name="play" size={14} />
					{t('common.slideshow')}
				</Button>
			{/if}
			<Button small href={`${resolve('/(app)/search')}?album=${id}`}>
				<Icon name="search" size={14} />
				{t('albums.id.searchInAlbum')}
			</Button>
			<Button small onclick={() => (showComments = !showComments)}>
				<Icon name="comment" size={14} />
				{t('albums.id.comments')}
			</Button>
			{#if isOwner}
				<Button small onclick={() => (sharing = true)}>
					<Icon name="users" size={14} />
					{t('albums.id.share')}
				</Button>
				<Button small onclick={() => (linking = true)}>
					<Icon name="share" size={14} />
					{t('albums.id.links')}
				</Button>
			{/if}
			{#if canEdit}
				<Button small onclick={startEdit}>{t('albums.id.edit')}</Button>
			{/if}
			{#if isOwner}
				<Button small onclick={() => (making = true)}>
					<Icon name="plus" size={14} />
					{t('albums.id.albumInside')}
				</Button>
				<Button small onclick={startMove}>{t('albums.id.moveTo')}</Button>
			{/if}
			{#if isOwner}
				<Button small variant="danger" onclick={() => (confirmDelete = true)}
					>{t('common.delete')}</Button
				>
			{:else}
				<Button small onclick={leave}>{t('albums.id.leave')}</Button>
			{/if}
		</div>
	</div>

	{#if gone}
		<Alert kind="warn">{t('albums.id.theConnectionToThisAlbum')}</Alert>
	{/if}

	{#if showComments}
		<Card title={t('albums.id.comments')}>
			<AlbumActivity albumId={id} revision={album.updatedAt} />
		</Card>
	{/if}

	{#if children.length}
		<section class="alb-children" aria-label={t('albums.id.albumsInside')}>
			<div class="alb-grid">
				{#each children as child (child.id)}
					<AlbumCard album={child} />
				{/each}
			</div>
		</section>
	{/if}

	{#if album.assetCount === 0 && !children.length}
		<section class="card glass">
			<div class="card-b">
				<EmptyState
					icon="album"
					text={album.isSmart
						? t('albums.id.noPhotosMatchTheRules')
						: canAdd
							? t('albums.id.thisAlbumIsEmptyUpload')
							: t('albums.id.thisAlbumIsEmpty')}
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
					aria-label={t('albums.id.setAsCover')}
					title={t('albums.id.setAsCover')}
					onclick={() => setCover(ids[0], clear)}><Icon name="photo" /></button
				>
			{/if}
			{#if canAdd}
				<button
					type="button"
					class="icon-btn"
					aria-label={t('albums.id.removeFromAlbum')}
					title={t('albums.id.removeFromAlbum')}
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
			playlist={(photo) => timeline?.playlist(photo) ?? Promise.resolve([])}
		/>
	{/if}

	{#if slides}
		<Slideshow items={slides} startId={slides[0].id} onClose={() => (slides = undefined)} />
	{/if}

	<ShareDialog {album} bind:open={sharing} onChanged={load} />
	<LinksDialog {album} bind:open={linking} />

	<Dialog title={t('albums.id.editAlbum')} bind:open={editing}>
		<form id="edit-album" class="form" onsubmit={save}>
			<Input label={t('common.name')} required maxlength={200} bind:value={title} />
			<Input label={t('common.description')} bind:value={description} />
			<Select
				label={t('albums.id.order')}
				bind:value={order}
				options={[
					{ value: 'newest', label: t('albums.id.newestFirst') },
					{ value: 'oldest', label: t('albums.id.oldestFirst') }
				]}
			/>
			{#if album.isSmart}<RulesForm bind:rules />{/if}
		</form>
		{#snippet footer()}
			<Button onclick={() => (editing = false)}>{t('common.cancel')}</Button>
			<Button type="submit" form="edit-album" variant="gold">{t('common.save')}</Button>
		{/snippet}
	</Dialog>

	<Dialog title={t('albums.id.newAlbumInside')} bind:open={making}>
		<form id="child-album" class="form" onsubmit={makeChild}>
			<Input label={t('common.name')} required maxlength={200} bind:value={childTitle} />
		</form>
		{#snippet footer()}
			<Button onclick={() => (making = false)}>{t('common.cancel')}</Button>
			<Button type="submit" form="child-album" variant="gold" disabled={!childTitle.trim()}
				>{t('albums.id.create')}</Button
			>
		{/snippet}
	</Dialog>

	<Dialog title={t('albums.id.moveTheAlbum')} bind:open={moving}>
		<form id="move-album" class="form" onsubmit={move}>
			<Select
				label={t('albums.id.into')}
				bind:value={moveTo}
				options={[
					{ value: '', label: t('albums.id.theTopAmongAllAlbums') },
					...destinations.map((entry) => ({ value: entry.id, label: entry.title }))
				]}
			/>
			<p class="alb-meta">
				{t('albums.id.seeingAnAlbumInsideAnother')}
			</p>
		</form>
		{#snippet footer()}
			<Button onclick={() => (moving = false)}>{t('common.cancel')}</Button>
			<Button type="submit" form="move-album" variant="gold">{t('albums.id.move')}</Button>
		{/snippet}
	</Dialog>

	<Dialog title={t('albums.id.deleteThisAlbum')} bind:open={confirmDelete}>
		<p>
			{t('albums.id.thePhotosStayInThe')}
			{#if children.length}
				{t('albums.id.theAlbumsInsideMoveTo')}
			{/if}
		</p>
		{#snippet footer()}
			<Button onclick={() => (confirmDelete = false)}>{t('common.cancel')}</Button>
			<Button variant="danger" onclick={remove}>{t('common.delete')}</Button>
		{/snippet}
	</Dialog>
{/if}
