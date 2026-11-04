<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AdminJobs } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
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
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
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
	{#if jobs}
		<Card title={tr('Redovi', 'Queues')}>
			{#each jobs.queues as queue (queue.name)}
				<div class="alb-list" data-queue={queue.name}>
					<b>{queue.name}</b>
					<span class="alb-meta">
						{queue.paused ? tr('Pauzirano', 'Paused') : tr('Radi', 'Running')} ·
						{tr('u redu', 'queued')}
						{queue.queued} · {tr('u obradi', 'running')}
						{queue.running}
					</span>
					<Button small onclick={() => act(() => api.pauseQueue(queue.name, !queue.paused))}>
						{queue.paused ? tr('Nastavi', 'Resume') : tr('Pauziraj', 'Pause')}
					</Button>
				</div>
			{/each}
		</Card>
		<Card title={tr('Neuspjeli poslovi', 'Failed jobs')}>
			{#if jobs.failed.length === 0}
				<p class="alb-meta">{tr('Nema neuspjelih poslova.', 'No failed jobs.')}</p>
			{/if}
			{#each jobs.failed as job (job.id)}
				<div class="alb-list">
					<b>{job.kind}</b>
					<span class="alb-meta">{job.error}</span>
					<Button small onclick={() => act(() => api.retryJob(job.id))}
						>{tr('Pokušaj opet', 'Try again')}</Button
					>
				</div>
			{/each}
		</Card>
	{/if}
	<Card title={tr('Datoteke', 'Files')}>
		<Kv label={tr('Obrađuju se', 'Processing')} value={String(data.processing)} />
		<Kv label={tr('S greškom', 'With errors')} value={String(data.failed)} />
	</Card>
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
