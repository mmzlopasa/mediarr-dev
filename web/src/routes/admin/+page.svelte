<script lang="ts">
	import { resolve } from '$app/paths';
	import { formatBytes } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import Stat from '#lib/design/components/Stat.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { diskUsedPercent, liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
	const jobsTotal = $derived(
		overview.data
			? overview.data.jobs.queued +
					overview.data.jobs.running +
					overview.data.jobs.completed +
					overview.data.jobs.failed
			: 0
	);
</script>

<svelte:head><title>{tr('Pregled', 'Overview')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr('Dobrodošli', 'Welcome')}</h1>
		<p>
			{tr(
				'Stanje biblioteke i poslužitelja na jednom mjestu.',
				'Library and server status in one place.'
			)}
		</p>
	</div>
</div>

{#if overview.failed}
	<Alert kind="err">{tr('Podaci se nisu učitali.', 'The data could not be loaded.')}</Alert>
{/if}

{#if overview.data}
	{@const data = overview.data}
	<div class="stats">
		<Stat label={tr('Korisnici', 'Users')} value={String(data.users)} />
		<Stat label={tr('Fotke', 'Photos')} value={String(data.photos)} />
		<Stat label={tr('Videi', 'Videos')} value={String(data.videos)} />
		<Stat
			label={tr('Pohrana', 'Storage')}
			value={formatBytes(data.libraryBytes)}
			pct={diskUsedPercent(data)}
		/>
	</div>
	<div class="grid2">
		<Card title={tr('Poslovi', 'Jobs')}>
			{#if jobsTotal === 0}
				<EmptyState icon="list" text={tr('Nema poslova u redu.', 'There are no queued jobs.')} />
			{:else}
				<Kv label={tr('U redu', 'Queued')} value={String(data.jobs.queued)} />
				<Kv label={tr('U obradi', 'Running')} value={String(data.jobs.running)} />
				<Kv label={tr('Dovršeno', 'Completed')} value={String(data.jobs.completed)} />
				{#if data.jobs.failed > 0}
					<a class="kv kv-bad" href={resolve('/admin/jobs')}
						><span>{tr('Neuspjelo', 'Failed')}</span><b>{data.jobs.failed} ›</b></a
					>
				{:else}
					<Kv label={tr('Neuspjelo', 'Failed')} value="0" />
				{/if}
			{/if}
		</Card>
		<Card title={tr('Sustav', 'System')}>
			<Kv label={tr('Verzija', 'Version')} value={data.version} />
			<Kv label={tr('Baza', 'Database')} value="PostgreSQL {data.databaseVersion}" />
			<Kv
				label={tr('Slobodno na disku', 'Free disk space')}
				value={formatBytes(data.diskFreeBytes)}
			/>
		</Card>
	</div>
{:else if !overview.failed}
	<div class="form"><Skeleton height="120px" /><Skeleton height="220px" /></div>
{/if}
