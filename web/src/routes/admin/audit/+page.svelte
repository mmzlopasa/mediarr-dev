<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AuditEntry } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let entries = $state<AuditEntry[]>();
	let failed = $state(false);
	let more = $state(false);

	const PAGE = 100;

	async function load(before?: number) {
		try {
			const page = await api.auditLog(before);
			entries = before ? [...(entries ?? []), ...page] : page;
			more = page.length === PAGE;
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(() => load());
</script>

<svelte:head><title>{tr('Dnevnik aktivnosti', 'Activity log')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{tr('Dnevnik aktivnosti', 'Activity log')}</h1></div>
</div>

{#if failed}
	<Alert kind="err">{tr('Dnevnik se nije učitao.', 'The activity log could not be loaded.')}</Alert>
{:else if !entries}
	<Skeleton height="220px" />
{:else if entries.length === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState icon="list" text={tr('Još nema zapisa.', 'Nothing recorded yet.')} />
		</div>
	</section>
{:else}
	<Card title={tr('Promjene, od najnovije', 'Changes, newest first')}>
		<p class="alb-meta">
			{tr(
				'Bilježi se tko je što promijenio, a ne sadržaj zahtjeva. Zapisi se čuvaju godinu dana.',
				'This records who changed what, not the content of a request. Entries are kept for a year.'
			)}
		</p>
		<div class="audit-list">
			{#each entries as entry (entry.id)}
				<div class="audit-row" class:audit-failed={entry.status >= 400}>
					<small>{new Date(entry.at).toLocaleString()}</small>
					<b>{entry.userEmail || tr('nepoznato', 'unknown')}</b>
					<span>{entry.method} {entry.route}</span>
					<small>{entry.target}</small>
					<small>{entry.status} · {entry.ip}</small>
				</div>
			{/each}
		</div>
		{#if more}
			<Button small onclick={() => load(entries?.at(-1)?.id)}
				>{tr('Učitaj starije', 'Load older')}</Button
			>
		{/if}
	</Card>
{/if}
