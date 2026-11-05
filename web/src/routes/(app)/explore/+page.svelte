<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type Memory, type PeopleList } from '#lib/api.ts';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';

	const PEOPLE_SHOWN = 12;
	const item = appNav.find((candidate) => candidate.path === '/explore') ?? appNav[0];

	type Places = Awaited<ReturnType<typeof api.explorePlaces>>['places'];
	let people = $state<PeopleList>();
	let places = $state<Places>();
	let memories = $state<Memory[]>();
	let peopleFailed = $state(false);
	let placesFailed = $state(false);
	let memoriesFailed = $state(false);

	const shownPeople = $derived(
		(people?.people ?? [])
			.filter((person) => !person.hidden && person.name !== '')
			.toSorted((a, b) => b.assetCount - a.assetCount)
			.slice(0, PEOPLE_SHOWN)
	);

	function today(): string {
		const now = new Date();
		const pad = (value: number) => String(value).padStart(2, '0');
		return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
	}

	// Each part stands alone: one that cannot be read leaves the others in place.
	onMount(() => {
		api.people().then(
			(list) => (people = list),
			() => (peopleFailed = true)
		);
		api.explorePlaces().then(
			(list) => (places = list.places),
			() => (placesFailed = true)
		);
		api.memories(today()).then(
			(list) => (memories = list),
			() => (memoriesFailed = true)
		);
	});
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
</div>

<section class="explore-part">
	<h2><a href={resolve('/(app)/people')}>{tr('Ljudi', 'People')}</a></h2>
	{#if peopleFailed}
		<p class="alb-meta">{tr('Osobe se nisu učitale.', 'People could not be loaded.')}</p>
	{:else if !people}
		<Skeleton height="160px" />
	{:else if shownPeople.length === 0}
		<p class="alb-meta">{tr('Još nema osoba s imenom.', 'No named people yet.')}</p>
	{:else}
		<div class="alb-grid">
			{#each shownPeople as person (person.id)}
				<a class="alb-card" href={resolve('/(app)/people/[id]', { id: person.id })}>
					<span class="alb-cover"
						><img src="/api/people/{person.id}/thumbnail" alt="" loading="lazy" /></span
					>
					<span class="alb-name">{person.name}</span>
					<span class="alb-meta">{person.assetCount}</span>
				</a>
			{/each}
		</div>
	{/if}
</section>

<section class="explore-part">
	<h2><a href={resolve('/(app)/map')}>{tr('Mjesta', 'Places')}</a></h2>
	{#if placesFailed}
		<p class="alb-meta">{tr('Mjesta se nisu učitala.', 'Places could not be loaded.')}</p>
	{:else if !places}
		<Skeleton height="160px" />
	{:else if places.length === 0}
		<p class="alb-meta">{tr('Još nema fotki s mjestom.', 'No photos with a place yet.')}</p>
	{:else}
		<div class="alb-grid">
			{#each places as place (`${place.name}${place.country}`)}
				<a class="alb-card" href="{resolve('/(app)/search')}?q={encodeURIComponent(place.name)}">
					<span class="alb-cover"
						><img src="/api/assets/{place.coverId}/thumbnail" alt="" loading="lazy" /></span
					>
					<span class="alb-name">{place.name}</span>
					<span class="alb-meta">{place.country} · {place.assetCount}</span>
				</a>
			{/each}
		</div>
	{/if}
</section>

<section class="explore-part">
	<h2><a href={resolve('/(app)/memories')}>{tr('Uspomene', 'Memories')}</a></h2>
	{#if memoriesFailed}
		<p class="alb-meta">{tr('Uspomene se nisu učitale.', 'Memories could not be loaded.')}</p>
	{:else if !memories}
		<Skeleton height="160px" />
	{:else if memories.length === 0}
		<p class="alb-meta">{tr('Danas nema uspomena.', 'No memories today.')}</p>
	{:else}
		<div class="alb-grid">
			{#each memories as memory (memory.kind + memory.title)}
				<a class="alb-card" href={resolve('/(app)/memories')}>
					<span class="alb-cover"
						><img src="/api/assets/{memory.items[0].id}/thumbnail" alt="" loading="lazy" /></span
					>
					<span class="alb-name">{memory.title}</span>
					<span class="alb-meta">{memory.items.length}</span>
				</a>
			{/each}
		</div>
	{/if}
</section>
