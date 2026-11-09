<script lang="ts">
	import ShareButton from '#lib/design/components/ShareButton.svelte';
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, type AssetList } from '#lib/api.ts';
	import Stories from '#lib/organize/Stories.svelte';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import UploadButton from '#lib/design/components/UploadButton.svelte';
	import { t, k, type Key } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';
	import AddToAlbum from '#lib/albums/AddToAlbum.svelte';
	import MoveToVault from '#lib/organize/MoveToVault.svelte';
	import TagButton from '#lib/organize/TagButton.svelte';
	import {
		clearFinishedUploads,
		isPreparingUpload,
		uploads,
		type UploadStatus
	} from '#lib/uploads.svelte.ts';

	const BUSY_POLL_MS = 2000;
	const IDLE_POLL_MS = 30000;
	const item = appNav[0];

	let timeline = $state<Timeline>();
	let total = $state<number | undefined>();
	let problems = $state<AssetList>();

	const processing = $derived(problems?.processing ?? 0);
	const uploading = $derived(
		uploads().some((upload) => upload.status === 'queued' || upload.status === 'uploading')
	);
	const finished = $derived(
		uploads().filter((upload) => upload.status === 'done' || upload.status === 'duplicate').length
	);

	// Photos from a partner have no neighbours on the server, so the viewer follows what is shown.
	let partnersShown = $state(false);

	async function refresh() {
		api
			.partners()
			.then((partners) => (partnersShown = partners.received.some((entry) => entry.inTimeline)))
			.catch(() => {});
		try {
			problems = await api.listProblems();
		} catch {
			// The timeline reports a server that does not answer.
		}
		await timeline?.refresh();
	}

	onMount(() => {
		refresh();
	});

	$effect(() => {
		const delay = processing > 0 || uploading ? BUSY_POLL_MS : IDLE_POLL_MS;
		const timer = setInterval(refresh, delay);
		return () => clearInterval(timer);
	});

	// A finished upload creates an asset, so show it right away.
	$effect(() => {
		if (finished > 0) refresh();
	});

	const uploadLabels: Record<UploadStatus, Key> = {
		queued: k('home.upload.queued'),
		uploading: k('home.upload.uploading'),
		done: k('home.upload.done'),
		duplicate: k('home.upload.duplicate'),
		failed: k('home.upload.failed')
	};

	// The viewer opens over the timeline as shallow routing, so the scroll position survives.
	function open(id: string) {
		pushState(resolve('/(app)/photos/[id]', { id }), { viewer: id });
	}
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<!-- The month is the title on screen; the page name stays for screen readers. -->
<div class="ph lib-head">
	<div><h1>{t(item.label)}</h1></div>
	<div class="ph-a">
		{#if processing > 0}
			<Badge kind="warn">{t('home.processingProcessing', { processing })}</Badge>
		{/if}
	</div>
</div>

{#if isPreparingUpload()}
	<Alert kind="ok">
		{t('home.yourDeviceIsPreparingThe')}
	</Alert>
{/if}

{#if uploads().length > 0}
	<Card title={t('home.upload')}>
		{#snippet actions()}
			{#if uploads().some((upload) => upload.status === 'failed')}
				<Button small onclick={clearFinishedUploads}>{t('home.clearFailed')}</Button>
			{/if}
		{/snippet}
		{#each uploads() as upload (upload.id)}
			<div class="kv">
				<span>{upload.name}</span>
				<b>{t(uploadLabels[upload.status])}</b>
			</div>
			{#if upload.status === 'uploading'}
				<Bar
					pct={upload.total ? Math.round((upload.loaded / upload.total) * 100) : 0}
					label={upload.name}
					progress
				/>
			{/if}
			{#if upload.error}<Alert kind="err">{upload.error}</Alert>{/if}
		{/each}
	</Card>
{/if}

{#if total === 0 && uploads().length === 0 && processing === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState icon={item.icon} text={item.empty ? t(item.empty) : ''}>
				{#snippet cta()}<UploadButton />{/snippet}
			</EmptyState>
		</div>
	</section>
{/if}

<Stories />

<Timeline bind:this={timeline} onOpen={open} onCount={(count) => (total = count)}>
	{#snippet selectionActions(ids, clear)}
		<ShareButton {ids} onDone={clear} />
		<AddToAlbum {ids} onDone={clear} />
		<TagButton {ids} onDone={clear} />
		<MoveToVault
			{ids}
			onDone={() => {
				clear();
				timeline?.reloadLoaded();
			}}
		/>
	{/snippet}
</Timeline>

{#if page.state.viewer}
	<Viewer
		id={page.state.viewer}
		onClose={() => history.back()}
		onNavigate={(id) => replaceState(resolve('/(app)/photos/[id]', { id }), { viewer: id })}
		onChanged={() => timeline?.reloadLoaded()}
		neighbours={partnersShown ? (id) => timeline?.neighbours(id) ?? {} : undefined}
		strip={(id) => timeline?.around(id) ?? []}
		playlist={(id) => timeline?.playlist(id) ?? Promise.resolve([])}
	/>
{/if}
