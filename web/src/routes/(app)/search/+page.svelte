<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { api, type Features, type SearchResult } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { lang, tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import { blurUrl } from '#lib/timeline/blur.ts';
	import FilterPanel from '#lib/search/FilterPanel.svelte';
	import { FILTER_KEYS, chipsFor, hasSearch, withoutChip } from '#lib/search/filters.ts';

	import Viewer from '#lib/timeline/Viewer.svelte';

	const item = appNav.find((candidate) => candidate.path === '/search') ?? appNav[0];

	const query = $derived(page.url.searchParams.get('q')?.trim() ?? '');
	// A copy to read and build on; the page's own is read only.
	const params = $derived(new URLSearchParams(page.url.searchParams.toString()));
	const searching = $derived(hasSearch(params));
	const chosenCount = $derived(
		FILTER_KEYS.filter((key) => key !== 'people' && params.has(key)).length
	);
	let panel = $state(false);
	let typed = $state('');
	let result = $state<SearchResult>();
	let failed = $state(false);
	let loading = $state(false);

	$effect(() => {
		const current = params;
		typed = current.get('q') ?? '';
		result = undefined;
		failed = false;
		if (!hasSearch(current)) return;
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

	/** The same page with another search, which keeps the filters chosen. */
	function go(next: URLSearchParams) {
		// eslint-disable-next-line svelte/no-navigation-without-resolve -- the same page, with a query
		goto(`${page.url.pathname}?${next.toString()}`);
	}

	function submit(event: SubmitEvent) {
		event.preventDefault();
		// eslint-disable-next-line svelte/prefer-svelte-reactivity -- a new address, built once
		const next = new URLSearchParams(params);
		const words = typed.trim();
		if (words) next.set('q', words);
		else next.delete('q');
		// New words are read for filters again.
		next.delete('plain');
		go(next);
	}

	const day = (iso: string) =>
		new Date(`${iso}T12:00:00`).toLocaleDateString(lang(), {
			day: 'numeric',
			month: 'short',
			year: 'numeric'
		});
	const chips = $derived(result ? chipsFor(result.filters, params, tr, day) : []);

	function neighbours(id: string) {
		const items = result?.items ?? [];
		const index = items.findIndex((entry) => entry.id === id);
		return index < 0 ? {} : { newer: items[index - 1]?.id, older: items[index + 1]?.id };
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr(item.hr, item.en)}</h1></div></div>

<form class="search-bar" onsubmit={submit}>
	<Input
		label={tr('Što tražite?', 'What are you looking for?')}
		placeholder={tr('pas na plaži, Hvar 2024, račun…', 'dog on a beach, Hvar 2024, receipt…')}
		bind:value={typed}
	/>
	<Button type="submit" variant="gold" disabled={!typed.trim() && !chosenCount}
		>{tr('Traži', 'Search')}</Button
	>
	<Button onclick={() => (panel = !panel)} aria-expanded={panel}
		>{tr('Filtri', 'Filters')}{chosenCount ? ` · ${chosenCount}` : ''}</Button
	>
	{#if askOn}
		<Button disabled={!typed.trim() || asking} onclick={ask}>
			{asking ? tr('Razmišljam…', 'Thinking…') : tr('Pitaj', 'Ask')}
		</Button>
	{/if}
</form>
{#if panel}
	<FilterPanel
		{params}
		onClose={() => (panel = false)}
		onApply={(next) => {
			panel = false;
			go(next);
		}}
	/>
{/if}
{#if asked && query}
	<p class="alb-meta" data-testid="asked">
		{tr('Za pitanje', 'For the question')} „{asked}”: {query}
	</p>
{/if}

{#if failed}
	<Alert kind="err">{tr('Pretraga nije uspjela.', 'The search failed.')}</Alert>
{:else if loading}
	<Skeleton height="220px" />
{:else if !searching}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon={item.icon}
				text={tr(
					'Opišite što tražite, na hrvatskom ili engleskom, ili odaberite filtre.',
					'Describe what you are looking for, in English or Croatian, or choose filters.'
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
	{#if chips.length}
		<ul class="sf-on" aria-label={tr('Filtri u pretrazi', 'Filters in this search')}>
			{#each chips as chip (chip.key + (chip.value ?? ''))}
				<li class:found={chip.found}>
					<span>{chip.label}</span>
					<button
						type="button"
						aria-label={tr(`Makni ${chip.label}`, `Remove ${chip.label}`)}
						title={chip.found
							? tr(
									'Pronađeno u riječima; makni i traži kao riječ',
									'Found in the words; remove to search it as a word'
								)
							: tr('Makni', 'Remove')}
						onclick={() => go(withoutChip(params, chip, result!.filters))}>×</button
					>
				</li>
			{/each}
		</ul>
	{/if}
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
		playlist={async () =>
			(result?.items ?? []).map((found) => ({ id: found.id, kind: found.kind }))}
	/>
{/if}
