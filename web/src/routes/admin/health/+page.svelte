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
	import { tr } from '#lib/i18n.svelte.ts';
	import { liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();
	let health = $state<AdminHealth>();
	let integrity = $state<IntegrityReport>();
	let started = $state(false);
	const problemNames = $derived({
		missing: tr('nedostaje', 'missing'),
		unreadable: tr('ne može se pročitati', 'cannot be read'),
		changed: tr('promijenjena', 'changed')
	});

	async function runIntegrity(thorough: boolean) {
		try {
			await api.runIntegrity(thorough);
			started = true;
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije pokrenuto.', 'Not started.')
			);
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

<Card title={tr('Provjera originala', 'Check the originals')}>
	<p class="alb-meta">
		{tr(
			'Provjera ne mijenja nijednu datoteku. Temeljita čita svaku datoteku i traje koliko i čitanje cijele biblioteke.',
			'A check changes no file. A thorough one reads every file and takes as long as reading the whole library.'
		)}
	</p>
	{#if integrity?.finishedAt}
		<Kv
			label={tr('Zadnja provjera', 'Last check')}
			value={new Date(integrity.finishedAt).toLocaleString()}
		/>
		<Kv label={tr('Provjereno', 'Checked')} value={String(integrity.checked)} />
		<Kv label={tr('Problema', 'Problems')} value={String(integrity.total)} />
		{#each integrity.problems as problem (problem.path)}
			<Kv label={problemNames[problem.problem]} value={problem.path} />
		{/each}
	{:else if integrity}
		<p class="alb-meta">{tr('Još nije provjereno.', 'Not checked yet.')}</p>
	{/if}
	{#if started}
		<p class="alb-meta" role="status">
			{tr(
				'Pokrenuto. Izvještaj će biti ovdje kad završi.',
				'Started. The report will be here when it finishes.'
			)}
		</p>
	{/if}
	<div class="integrity-run">
		<Button variant="gold" small onclick={() => runIntegrity(false)}
			>{tr('Provjeri sada', 'Check now')}</Button
		>
		<Button small onclick={() => runIntegrity(true)}>{tr('Temeljito', 'Thoroughly')}</Button>
	</div>
</Card>

<SnapshotsCard />
