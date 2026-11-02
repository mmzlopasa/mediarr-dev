<script lang="ts">
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
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
		</div>
		<Kv label={tr('Baza', 'Database')} value="PostgreSQL {data.databaseVersion}" />
		<Kv label={tr('Verzija', 'Version')} value={data.version} />
		<Kv label={tr('Obrađuje se', 'Processing')} value={String(data.processing)} />
		<Kv label={tr('Datoteke s greškom', 'Files with errors')} value={String(data.failed)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
