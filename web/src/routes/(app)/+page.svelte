<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AssetList } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import UploadButton from '#lib/design/components/UploadButton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import { clearFinishedUploads, uploads, type UploadStatus } from '#lib/uploads.svelte.ts';

	const POLL_MS = 2000;
	const item = appNav[0];

	let list = $state<AssetList>();
	let loadFailed = $state(false);

	const hasWork = $derived(
		(list?.processing ?? 0) > 0 ||
			uploads().some((upload) => upload.status === 'queued' || upload.status === 'uploading')
	);
	let lastFinished = $derived(
		uploads().filter((upload) => upload.status === 'done' || upload.status === 'duplicate').length
	);

	async function refresh() {
		try {
			list = await api.listAssets();
			loadFailed = false;
		} catch {
			loadFailed = true;
		}
	}

	onMount(refresh);

	$effect(() => {
		if (!hasWork) return;
		const timer = setInterval(refresh, POLL_MS);
		return () => clearInterval(timer);
	});

	// A finished upload creates an asset, so show it right away.
	$effect(() => {
		if (lastFinished > 0) refresh();
	});

	const uploadLabels: Record<UploadStatus, [string, string]> = {
		queued: ['Čeka', 'Queued'],
		uploading: ['Šalje se', 'Uploading'],
		done: ['Poslano', 'Uploaded'],
		duplicate: ['Već postoji', 'Already exists'],
		failed: ['Nije uspjelo', 'Failed']
	};
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
	<div class="ph-a"><UploadButton /></div>
</div>

{#if loadFailed}
	<Alert kind="err">{tr('Fotke se nisu učitale.', 'Photos could not be loaded.')}</Alert>
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

{#if list && list.total > 0}
	<Card title={tr(`Datoteke: ${list.total}`, `Files: ${list.total}`)}>
		<div class="tbl-w">
			<table class="tbl">
				<thead>
					<tr>
						<th>{tr('Naziv', 'Name')}</th>
						<th>{tr('Status', 'Status')}</th>
						<th class="ta-r">{tr('Veličina', 'Size')}</th>
					</tr>
				</thead>
				<tbody>
					{#each list.items as asset (asset.id)}
						<tr>
							<td data-l={tr('Naziv', 'Name')}><b>{asset.originalName}</b></td>
							<td data-l={tr('Status', 'Status')}>
								{#if asset.status === 'ready'}
									<Badge kind="ok">{tr('Spremno', 'Ready')}</Badge>
								{:else if asset.status === 'failed'}
									<Badge kind="bad">{tr('Greška', 'Error')}</Badge>
									{#if asset.error}<small class="hint"> {asset.error}</small>{/if}
								{:else}
									<Badge kind="warn">{tr('Obrađuje se', 'Processing')}</Badge>
								{/if}
							</td>
							<td data-l={tr('Veličina', 'Size')} class="ta-r">{formatBytes(asset.sizeBytes)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</Card>
{:else if !list || list.total === 0}
	{#if uploads().length === 0}
		<section class="card glass">
			<div class="card-b">
				<EmptyState icon={item.icon} text={tr(item.emptyHr, item.emptyEn)} />
			</div>
		</section>
	{/if}
{/if}
