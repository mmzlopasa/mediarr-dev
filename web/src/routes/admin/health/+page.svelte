<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AdminHealth } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
	let health = $state<AdminHealth>();

	onMount(async () => {
		try {
			health = await api.adminHealth();
		} catch {
			health = undefined;
		}
	});
</script>

<svelte:head><title>{tr('Zdravlje', 'Health')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{tr('Zdravlje', 'Health')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{tr('Poslužitelj ne odgovara.', 'The server is not answering.')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={tr('Sustav', 'System')}>
		<div class="btn-row">
			<Badge kind="ok">{tr('Poslužitelj odgovara', 'Server is answering')}</Badge>
			{#if health}
				<Badge kind={health.workerRunning ? 'ok' : 'bad'}>
					{health.workerRunning
						? tr('Pozadinski poslovi rade', 'Background jobs are running')
						: tr('Pozadinski poslovi ne rade', 'Background jobs are not running')}
				</Badge>
				{#if health.mlEnabled}
					<Badge kind={health.mlRunning ? 'ok' : 'bad'}>
						{health.mlRunning
							? tr('Analiza slika radi', 'Picture analysis is running')
							: tr('Analiza slika ne odgovara', 'Picture analysis is not answering')}
					</Badge>
				{:else}
					<Badge kind="mute">{tr('Analiza slika nije uključena', 'Picture analysis is off')}</Badge>
				{/if}
			{/if}
		</div>
		<Kv label={tr('Baza', 'Database')} value="PostgreSQL {data.databaseVersion}" />
		{#if health}<Kv
				label={tr('Veličina baze', 'Database size')}
				value={formatBytes(health.databaseBytes)}
			/>{/if}
		<Kv label={tr('Verzija', 'Version')} value={data.version} />
		<Kv label={tr('Obrađuje se', 'Processing')} value={String(data.processing)} />
		<Kv label={tr('Datoteke s greškom', 'Files with errors')} value={String(data.failed)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
