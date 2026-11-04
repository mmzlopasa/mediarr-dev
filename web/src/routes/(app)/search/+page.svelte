<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { api, type Features, type SearchResult } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import { blurUrl } from '#lib/timeline/blur.ts';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const item = appNav.find((candidate) => candidate.path === '/search') ?? appNav[0];

	const query = $derived(page.url.searchParams.get('q')?.trim() ?? '');
	let typed = $state('');
	let result = $state<SearchResult>();
	let failed = $state(false);
	let loading = $state(false);

	$effect(() => {
		const current = query;
		typed = current;
		result = undefined;
		failed = false;
		if (!current) return;
		let stale = false;
		loading = true;
		api
			.search(current)
			.then((found) => {
				if (!stale) result = found;
			})
			.catch(() => {
				if (!stale) failed = true;
			})
			.finally(() => {
				if (!stale) loading = false;
			});
		return () => {
			stale = true;
		};
	});

	let askOn = $state(false);
	let asking = $state(false);
	let asked = $state('');

	onMount(async () => {
		const features = await api.features().catch(() => ({}) as Features);
		askOn = features.descriptions ?? false;
	});

	// A model on a machine with no graphics card can take a while, and says so meanwhile.
	async function ask() {
		const question = typed.trim();
		if (!question) return;
		asking = true;
		try {
			const { query: words } = await api.askSearch(question);
			asked = question;
			// eslint-disable-next-line svelte/no-navigation-without-resolve -- the same page, with a query
			await goto(`${page.url.pathname}?q=${encodeURIComponent(words)}`);
		} catch {
			asked = '';
			// eslint-disable-next-line svelte/no-navigation-without-resolve -- the same page, with a query
			await goto(`${page.url.pathname}?q=${encodeURIComponent(question)}`);
		} finally {
			asking = false;
		}
	}

	function submit(event: SubmitEvent) {
		event.preventDefault();
		// eslint-disable-next-line svelte/no-navigation-without-resolve -- the same page, with a query
		goto(`${page.url.pathname}?q=${encodeURIComponent(typed.trim())}`);
	}

	function neighbours(id: string) {
		const items = result?.items ?? [];
		const index = items.findIndex((entry) => entry.id === id);
		return index < 0 ? {} : { newer: items[index - 1]?.id, older: items[index + 1]?.id };
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr(item.hr, item.en)}</h1></div></div>

<form class="map-bar" onsubmit={submit}>
	<Input
		label={tr('Što tražite?', 'What are you looking for?')}
		placeholder={tr('pas na plaži, Hvar 2024, račun…', 'dog on a beach, Hvar 2024, receipt…')}
		bind:value={typed}
	/>
	<Button type="submit" variant="gold" disabled={!typed.trim()}>{tr('Traži', 'Search')}</Button>
	{#if askOn}
		<Button disabled={!typed.trim() || asking} onclick={ask}>
			{asking ? tr('Razmišljam…', 'Thinking…') : tr('Pitaj', 'Ask')}
		</Button>
	{/if}
</form>
{#if asked && query}
	<p class="alb-meta" data-testid="asked">
		{tr('Za pitanje', 'For the question')} „{asked}”: {query}
	</p>
{/if}

{#if failed}
	<Alert kind="err">{tr('Pretraga nije uspjela.', 'The search failed.')}</Alert>
{:else if loading}
	<Skeleton height="220px" />
{:else if !query}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon={item.icon}
				text={tr(
					'Opišite što tražite, na hrvatskom ili engleskom.',
					'Describe what you are looking for, in English or Croatian.'
				)}
			/>
		</div>
	</section>
{:else if result}
	{#if !result.smart}
		<Alert kind="warn">
			{tr(
				'Pametna pretraga nije uključena ili nije dostupna, pa se traži samo tekst na slikama, nazivi datoteka i filtri.',
				'Smart search is off or not available, so only text on pictures, file names and filters are searched.'
			)}
		</Alert>
	{/if}
	<div class="ph-a">
		{#if result.filters.from}<Badge kind="acc">{result.filters.from} – {result.filters.to}</Badge
			>{/if}
		{#if result.filters.person}<Badge kind="acc">{result.filters.person}</Badge>{/if}
		{#if result.filters.place}<Badge kind="acc">{result.filters.place}</Badge>{/if}
		{#if result.filters.camera}<Badge kind="acc">{result.filters.camera}</Badge>{/if}
	</div>
	{#if result.items.length === 0}
		<section class="card glass">
			<div class="card-b">
				<EmptyState icon={item.icon} text={tr('Ništa nije pronađeno.', 'Nothing was found.')} />
			</div>
		</section>
	{:else}
		<div class="map-grid search-grid">
			{#each result.items as found (found.id)}
				{@const blur = blurUrl(found.blurhash)}
				<button
					type="button"
					aria-label={tr('Otvori', 'Open')}
					style={blur ? `background-image:url(${blur});background-size:cover` : ''}
					onclick={() => pushState('', { viewer: found.id })}
				>
					<img src="/api/assets/{found.id}/thumbnail" alt="" loading="lazy" />
				</button>
			{/each}
		</div>
	{/if}
{/if}

{#if page.state.viewer}
	<Viewer
		id={page.state.viewer}
		onClose={() => history.back()}
		onNavigate={(photo) => replaceState('', { viewer: photo })}
		onChanged={() => {}}
		{neighbours}
	/>
{/if}
