<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AdminHealth, type IntegrityReport } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import SnapshotsCard from '#lib/organize/SnapshotsCard.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { dateLocale, t } from '#lib/i18n.svelte.ts';
	import { liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
	let health = $state<AdminHealth>();
	let integrity = $state<IntegrityReport>();
	let started = $state(false);
	const problemNames = $derived({
		missing: t('admin.health.missing'),
		unreadable: t('admin.health.cannotBeRead'),
		changed: t('admin.health.changed')
	});

	async function runIntegrity(thorough: boolean) {
		try {
			await api.runIntegrity(thorough);
			started = true;
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('admin.health.notStarted'));
		}
	}

	onMount(async () => {
		try {
			health = await api.adminHealth();
			integrity = await api.integrity();
		} catch {
			health = undefined;
		}
	});
</script>

<svelte:head><title>{t('admin.health.health')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{t('admin.health.health')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{t('admin.health.theServerIsNotAnswering')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={t('admin.health.system')}>
		<div class="btn-row">
			<Badge kind="ok">{t('admin.health.serverIsAnswering')}</Badge>
			{#if health}
				<Badge kind={health.workerRunning ? 'ok' : 'bad'}>
					{health.workerRunning
						? t('admin.health.backgroundJobsAreRunning')
						: t('admin.health.backgroundJobsAreNotRunning')}
				</Badge>
				{#if health.mlEnabled}
					<Badge kind={health.mlRunning ? 'ok' : 'bad'}>
						{health.mlRunning
							? t('admin.health.pictureAnalysisIsRunning')
							: t('admin.health.pictureAnalysisIsNotAnswering')}
					</Badge>
				{:else}
					<Badge kind="mute">{t('admin.health.pictureAnalysisIsOff')}</Badge>
				{/if}
			{/if}
		</div>
		<Kv label={t('admin.health.database')} value="PostgreSQL {data.databaseVersion}" />
		{#if health}<Kv
				label={t('admin.health.databaseSize')}
				value={formatBytes(health.databaseBytes)}
			/>{/if}
		<Kv label={t('admin.health.version')} value={data.version} />
		<Kv label={t('admin.health.processing')} value={String(data.processing)} />
		<Kv label={t('admin.health.filesWithErrors')} value={String(data.failed)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}

{#if health?.ml}
	{@const ml = health.ml}
	<Card title={t('admin.health.analysisService')}>
		<div class="btn-row" data-testid="ml-state">
			{#if ml.state === 'connected'}
				<Badge kind="ok">{t('admin.health.mlConnected')}</Badge>
			{:else if ml.state === 'wrongToken'}
				<Badge kind="bad">{t('admin.health.mlWrongToken')}</Badge>
			{:else}
				<Badge kind="bad">{t('admin.health.mlUnreachable')}</Badge>
			{/if}
		</div>
		{#if ml.models}
			{@const loaded = ml.models.filter((model) => model.loaded).map((model) => model.name)}
			<Kv
				label={t('admin.health.mlLoadedModels')}
				value={loaded.length ? loaded.join(', ') : t('admin.health.mlNoneLoaded')}
			/>
		{/if}
		{#if ml.rssBytes != null}
			<Kv label={t('admin.health.mlMemory')} value={formatBytes(ml.rssBytes)} />
		{/if}
		{#if ml.acceleration}
			<Kv
				label={t('admin.health.mlAcceleration')}
				value={`${ml.acceleration.requested} (${ml.acceleration.providers.join(', ')})`}
			/>
		{/if}
	</Card>
{/if}

<Card title={t('admin.health.checkTheOriginals')}>
	<p class="alb-meta">
		{t('admin.health.aCheckChangesNoFile')}
	</p>
	{#if integrity?.finishedAt}
		<Kv
			label={t('admin.health.lastCheck')}
			value={new Date(integrity.finishedAt).toLocaleString(dateLocale())}
		/>
		<Kv label={t('admin.health.checked')} value={String(integrity.checked)} />
		<Kv label={t('admin.health.problems')} value={String(integrity.total)} />
		{#each integrity.problems as problem (problem.path)}
			<Kv label={problemNames[problem.problem]} value={problem.path} />
		{/each}
	{:else if integrity}
		<p class="alb-meta">{t('admin.health.notCheckedYet')}</p>
	{/if}
	{#if started}
		<p class="alb-meta" role="status">
			{t('admin.health.startedTheReportWillBe')}
		</p>
	{/if}
	<div class="integrity-run">
		<Button variant="gold" small onclick={() => runIntegrity(false)}
			>{t('admin.health.checkNow')}</Button
		>
		<Button small onclick={() => runIntegrity(true)}>{t('admin.health.thoroughly')}</Button>
	</div>
</Card>

<SnapshotsCard />
