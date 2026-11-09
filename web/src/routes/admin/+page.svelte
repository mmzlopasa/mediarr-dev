<script lang="ts">
	import { resolve } from '$app/paths';
	import { formatBytes } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import Stat from '#lib/design/components/Stat.svelte';
	import { t } from '#lib/i18n.svelte.ts';
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

<svelte:head><title>{t('admin.overview')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t('admin.welcome')}</h1>
		<p>
			{t('admin.libraryAndServerStatusIn')}
		</p>
	</div>
</div>

{#if overview.failed}
	<Alert kind="err">{t('common.theDataCouldNotBe')}</Alert>
{/if}

{#if overview.data}
	{@const data = overview.data}
	<div class="stats">
		<Stat label={t('admin.users')} value={String(data.users)} />
		<Stat label={t('common.photos')} value={String(data.photos)} />
		<Stat label={t('common.videos')} value={String(data.videos)} />
		<Stat
			label={t('admin.storage')}
			value={formatBytes(data.libraryBytes)}
			pct={diskUsedPercent(data)}
		/>
	</div>
	<div class="grid2">
		<Card title={t('admin.jobs')}>
			{#if jobsTotal === 0}
				<EmptyState icon="list" text={t('admin.thereAreNoQueuedJobs')} />
			{:else}
				<Kv label={t('admin.queued')} value={String(data.jobs.queued)} />
				<Kv label={t('admin.running')} value={String(data.jobs.running)} />
				<Kv label={t('admin.completed')} value={String(data.jobs.completed)} />
				{#if data.jobs.failed > 0}
					<a class="kv kv-bad" href={resolve('/admin/jobs')}
						><span>{t('admin.failed')}</span><b>{data.jobs.failed} ›</b></a
					>
				{:else}
					<Kv label={t('admin.failed')} value="0" />
				{/if}
			{/if}
		</Card>
		<Card title={t('admin.system')}>
			<Kv label={t('admin.version')} value={data.version} />
			<Kv label={t('admin.database')} value="PostgreSQL {data.databaseVersion}" />
			<Kv label={t('admin.freeDiskSpace')} value={formatBytes(data.diskFreeBytes)} />
		</Card>
	</div>
{:else if !overview.failed}
	<div class="form"><Skeleton height="120px" /><Skeleton height="220px" /></div>
{/if}
