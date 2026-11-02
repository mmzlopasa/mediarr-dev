<script lang="ts">
	import { formatBytes } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { diskUsedPercent, liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
</script>

<svelte:head><title>{tr('Pohrana', 'Storage')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{tr('Pohrana', 'Storage')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{tr('Podaci se nisu učitali.', 'The data could not be loaded.')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={tr('Disk biblioteke', 'Library disk')}>
		<Kv label={tr('Originali', 'Originals')} value={formatBytes(data.libraryBytes)} />
		<Kv
			label={tr('Slobodno na disku', 'Free disk space')}
			value={formatBytes(data.diskFreeBytes)}
		/>
		<Kv label={tr('Veličina diska', 'Disk size')} value={formatBytes(data.diskTotalBytes)} />
		<Bar pct={diskUsedPercent(data)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
