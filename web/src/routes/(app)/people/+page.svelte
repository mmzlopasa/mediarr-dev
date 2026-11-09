<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type PeopleList } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
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
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{t(item.label)}</h1></div>
	{#if hiddenCount > 0}
		<div class="ph-a">
			<Button small onclick={() => (showHidden = !showHidden)}>
				{showHidden ? t('people.showTheOthers') : t('people.hiddenPeople')}
			</Button>
		</div>
	{/if}
</div>

{#if failed}
	<Alert kind="err">{t('people.peopleCouldNotBeLoaded')}</Alert>
{:else if !list}
	<Skeleton height="220px" />
{:else if !list.enabled && list.people.length === 0}
	<section class="card glass">
		<div class="card-b">
			<EmptyState icon={item.icon} text={t('people.faceRecognitionIsNotTurned')} />
		</div>
	</section>
{:else if shown.length === 0}
	<section class="card glass">
		<div class="card-b"><EmptyState icon={item.icon} text={item.empty ? t(item.empty) : ''} /></div>
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
				<span class="alb-name">{person.name || t('common.noName')}</span>
				<span class="alb-meta">{person.assetCount}</span>
				{#if showHidden}
					<Button small onclick={() => setHidden(person.id, false)}>{t('common.show')}</Button>
				{/if}
			</div>
		{/each}
	</div>
{/if}
