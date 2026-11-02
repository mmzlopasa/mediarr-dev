<script lang="ts">
	import Alert from '#lib/design/components/Alert.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
</script>

<svelte:head><title>{tr('Poslovi', 'Jobs')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{tr('Poslovi', 'Jobs')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{tr('Podaci se nisu učitali.', 'The data could not be loaded.')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={tr('Red poslova', 'Job queue')}>
		<Kv label={tr('U redu', 'Queued')} value={String(data.jobs.queued)} />
		<Kv label={tr('U obradi', 'Running')} value={String(data.jobs.running)} />
		<Kv label={tr('Dovršeno', 'Completed')} value={String(data.jobs.completed)} />
		<Kv label={tr('Neuspjelo', 'Failed')} value={String(data.jobs.failed)} />
	</Card>
	<Card title={tr('Datoteke', 'Files')}>
		<Kv label={tr('Obrađuju se', 'Processing')} value={String(data.processing)} />
		<Kv label={tr('S greškom', 'With errors')} value={String(data.failed)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
