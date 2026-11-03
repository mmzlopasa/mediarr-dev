<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, type AssetList } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import UploadButton from '#lib/design/components/UploadButton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';
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
	let showProblems = $state(false);

	const processing = $derived(problems?.processing ?? 0);
	const uploading = $derived(
		uploads().some((upload) => upload.status === 'queued' || upload.status === 'uploading')
	);
	const finished = $derived(
		uploads().filter((upload) => upload.status === 'done' || upload.status === 'duplicate').length
	);

	async function refresh() {
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

	const uploadLabels: Record<UploadStatus, [string, string]> = {
		queued: ['Čeka', 'Queued'],
		uploading: ['Šalje se', 'Uploading'],
		done: ['Poslano', 'Uploaded'],
		duplicate: ['Već postoji', 'Already exists'],
		failed: ['Nije uspjelo', 'Failed']
	};

	// The viewer opens over the timeline as shallow routing, so the scroll position survives.
	function open(id: string) {
		pushState(resolve('/(app)/photos/[id]', { id }), { viewer: id });
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
	<div class="ph-a">
		{#if processing > 0}
			<Badge kind="warn">{tr(`Obrađuje se: ${processing}`, `Processing: ${processing}`)}</Badge>
		{/if}
		<UploadButton />
	</div>
</div>

{#if isPreparingUpload()}
	<Alert kind="ok">
		{tr(
			'Mobitel priprema odabrane datoteke. Kod većih fotki i videa to može potrajati.',
			'Your device is preparing the selected files. With larger photos and videos this can take a while.'
		)}
	</Alert>
{/if}

{#if uploads().length > 0}
	<Card title={tr('Upload', 'Upload')}>
		{#snippet actions()}
			<Button small onclick={clearFinishedUploads}>{tr('Očisti gotove', 'Clear finished')}</Button>
		{/snippet}
		{#each uploads() as upload (upload.id)}
			<div class="kv">
				<span>{upload.name}</span>
				<b>{tr(...uploadLabels[upload.status])}</b>
			</div>
			{#if upload.status === 'uploading'}
				<Bar
					pct={upload.total ? Math.round((upload.loaded / upload.total) * 100) : 0}
					label={upload.name}
				/>
			{/if}
			{#if upload.error}<Alert kind="err">{upload.error}</Alert>{/if}
		{/each}
	</Card>
{/if}

{#if problems && problems.failed > 0}
	<Alert kind="warn">
		{tr(
			`Datoteke koje se nisu mogle obraditi: ${problems.failed}.`,
			`Files that could not be processed: ${problems.failed}.`
		)}
		<button type="button" class="linkish" onclick={() => (showProblems = !showProblems)}>
			{showProblems ? tr('Sakrij', 'Hide') : tr('Prikaži', 'Show')}
		</button>
	</Alert>
	{#if showProblems}
		<Card title={tr('Neobrađene datoteke', 'Unprocessed files')}>
			<div class="tbl-w">
				<table class="tbl">
					<tbody>
						{#each problems.items as asset (asset.id)}
							<tr>
								<td data-l={tr('Naziv', 'Name')}><b>{asset.originalName}</b></td>
								<td data-l={tr('Greška', 'Error')}>{asset.error ?? ''}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</Card>
	{/if}
{/if}

{#if total === 0 && uploads().length === 0 && processing === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState icon={item.icon} text={tr(item.emptyHr, item.emptyEn)} />
		</div>
	</section>
{/if}

<Timeline bind:this={timeline} onOpen={open} onCount={(count) => (total = count)} />

{#if page.state.viewer}
	<Viewer
		id={page.state.viewer}
		onClose={() => history.back()}
		onNavigate={(id) => replaceState(resolve('/(app)/photos/[id]', { id }), { viewer: id })}
		onChanged={() => timeline?.reloadLoaded()}
	/>
{/if}
