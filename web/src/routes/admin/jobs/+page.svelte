<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AdminJobs } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import { liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();

	let jobs = $state<AdminJobs>();

	async function loadJobs() {
		try {
			jobs = await api.adminJobs();
		} catch {
			jobs = undefined;
		}
	}

	onMount(loadJobs);

	async function act(action: () => Promise<void>) {
		try {
			await action();
			await loadJobs();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t('admin.jobs.jobs')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{t('admin.jobs.jobs')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{t('common.theDataCouldNotBe')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={t('admin.jobs.jobQueue')}>
		<Kv label={t('admin.jobs.queued')} value={String(data.jobs.queued)} />
		<Kv label={t('admin.jobs.running')} value={String(data.jobs.running)} />
		<Kv label={t('admin.jobs.completed')} value={String(data.jobs.completed)} />
		<Kv label={t('admin.jobs.failed')} value={String(data.jobs.failed)} />
	</Card>
	{#if jobs}
		<Card title={t('admin.jobs.queues')}>
			{#each jobs.queues as queue (queue.name)}
				<div class="alb-list" data-queue={queue.name}>
					<b>{queue.name}</b>
					<span class="alb-meta">
						{queue.paused ? t('admin.jobs.paused') : t('admin.jobs.running2')} ·
						{t('admin.jobs.queued2')}
						{queue.queued} · {t('admin.jobs.running3')}
						{queue.running}
					</span>
					<Button small onclick={() => act(() => api.pauseQueue(queue.name, !queue.paused))}>
						{queue.paused ? t('common.resume') : t('admin.jobs.pause')}
					</Button>
				</div>
			{/each}
		</Card>
		<Card title={t('admin.jobs.failedJobs')}>
			{#if jobs.failed.length === 0}
				<p class="alb-meta">{t('admin.jobs.noFailedJobs')}</p>
			{/if}
			{#each jobs.failed as job (job.id)}
				<div class="alb-list">
					<b>{job.kind}</b>
					<span class="alb-meta">{job.error}</span>
					<Button small onclick={() => act(() => api.retryJob(job.id))}
						>{t('admin.jobs.tryAgain')}</Button
					>
				</div>
			{/each}
		</Card>
	{/if}
	<Card title={t('admin.jobs.files')}>
		<Kv label={t('admin.jobs.processing')} value={String(data.processing)} />
		<Kv label={t('admin.jobs.withErrors')} value={String(data.failed)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
