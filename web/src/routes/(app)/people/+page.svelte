<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type PeopleList } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';

	const POLL_MS = 10000;
	const item = appNav.find((candidate) => candidate.path === '/people') ?? appNav[0];

	let list = $state<PeopleList>();
	let failed = $state(false);
	let showHidden = $state(false);

	const shown = $derived(
		(list?.people ?? []).filter((person) => (showHidden ? person.hidden : !person.hidden))
	);
	const hiddenCount = $derived((list?.people ?? []).filter((person) => person.hidden).length);

	async function load() {
		try {
			list = await api.people();
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(() => {
		load();
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	async function setHidden(id: string, hidden: boolean) {
		try {
			await api.updatePerson(id, { hidden });
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
	{#if hiddenCount > 0}
		<div class="ph-a">
			<Button small onclick={() => (showHidden = !showHidden)}>
				{showHidden
					? tr('Prikaži ostale', 'Show the others')
					: tr('Skrivene osobe', 'Hidden people')}
			</Button>
		</div>
	{/if}
</div>

{#if failed}
	<Alert kind="err">{tr('Osobe se nisu učitale.', 'People could not be loaded.')}</Alert>
{:else if !list}
	<Skeleton height="220px" />
{:else if !list.enabled && list.people.length === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon={item.icon}
				text={tr(
					'Prepoznavanje lica nije uključeno na ovom serveru.',
					'Face recognition is not turned on for this server.'
				)}
			/>
		</div>
	</section>
{:else if shown.length === 0}
	<section class="card glass">
		<div class="card-b"><EmptyState icon={item.icon} text={tr(item.emptyHr, item.emptyEn)} /></div>
	</section>
{:else}
	<div class="alb-grid">
		{#each shown as person (person.id)}
			<div class="alb-card">
				<a href={resolve('/(app)/people/[id]', { id: person.id })}>
					<span class="alb-cover"
						><img src="/api/people/{person.id}/thumbnail" alt="" loading="lazy" /></span
					>
				</a>
				<span class="alb-name">{person.name || tr('Bez imena', 'No name')}</span>
				<span class="alb-meta">{person.assetCount}</span>
				{#if showHidden}
					<Button small onclick={() => setHidden(person.id, false)}>{tr('Prikaži', 'Show')}</Button>
				{/if}
			</div>
		{/each}
	</div>
{/if}
