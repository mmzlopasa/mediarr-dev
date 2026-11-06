<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { api, type MapPoints, type MapStyle, type Trip } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import PhotoMap from '#lib/map/PhotoMap.svelte';
	import { appNav } from '#lib/nav.ts';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const item = appNav.find((candidate) => candidate.path === '/map') ?? appNav[0];

	let points = $state.raw<MapPoints>();
	let everHadPoints = $state(false);
	let style = $state<MapStyle>();
	let trips = $state<Trip[]>([]);
	let failed = $state(false);
	let from = $state('');
	let to = $state('');
	let heatmap = $state(false);
	let focus = $state<{ lat: number; lon: number }>();
	let cluster = $state<string[]>([]);
	let showCluster = $state(false);
	let around = $state<string[]>([]);

	async function load() {
		try {
			points = await api.mapPoints(from, to);
			if (points.ids.length > 0) everHadPoints = true;
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(async () => {
		try {
			[style, trips] = await Promise.all([api.mapStyle(), api.mapTrips()]);
		} catch {
			failed = true;
		}
	});

	$effect(() => {
		void from;
		void to;
		load();
	});

	function open(id: string, list: string[] = []) {
		around = list;
		showCluster = false;
		pushState('', { viewer: id });
	}

	function chooseTrip(trip: Trip) {
		from = trip.from;
		to = trip.to;
		focus = { lat: trip.lat, lon: trip.lon };
	}

	function neighbours(id: string) {
		const index = around.indexOf(id);
		return index < 0 ? {} : { newer: around[index - 1], older: around[index + 1] };
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr(item.hr, item.en)}</h1>
		{#if points}
			<p>{tr(`S lokacijom: ${points.ids.length}`, `With a location: ${points.ids.length}`)}</p>
		{/if}
	</div>
	<div class="ph-a">
		<label class="sel-inline">
			<span>{tr('Od datuma', 'From date')}</span>
			<input class="in" type="date" bind:value={from} />
		</label>
		<label class="sel-inline">
			<span>{tr('Do datuma', 'To date')}</span>
			<input class="in" type="date" bind:value={to} />
		</label>
		<label class="tb-switch">
			<span>{tr('Toplinska karta', 'Heatmap')}</span>
			<input type="checkbox" class="switch" bind:checked={heatmap} />
		</label>
		{#if from || to}
			<Button
				small
				onclick={() => {
					from = '';
					to = '';
				}}>{tr('Očisti', 'Clear')}</Button
			>
		{/if}
	</div>
</div>

{#if failed}
	<Alert kind="err">{tr('Karta se nije učitala.', 'The map could not be loaded.')}</Alert>
{/if}

{#if !points || !style}
	{#if !failed}<Skeleton height="420px" />{/if}
{:else if !everHadPoints && points.ids.length === 0 && !from && !to}
	<section class="card glass">
		<div class="card-b"><EmptyState icon={item.icon} text={tr(item.emptyHr, item.emptyEn)} /></div>
	</section>
{:else}
	<PhotoMap
		{points}
		styleUrl={document.documentElement.dataset.theme === 'light' ? style.light : style.dark}
		{heatmap}
		{focus}
		onPhoto={(id) => open(id)}
		onCluster={(ids) => {
			cluster = ids;
			showCluster = true;
		}}
	/>
{/if}

{#if trips.length > 0}
	<Card title={tr('Putovanja', 'Trips')}>
		{#each trips as trip (trip.coverId)}
			<div class="alb-list">
				<b>{trip.places.join(', ') || tr('Bez naziva mjesta', 'No place name')}</b>
				<span class="alb-meta">{trip.from} – {trip.to} · {trip.count}</span>
				<Button small onclick={() => chooseTrip(trip)}>{tr('Prikaži', 'Show')}</Button>
			</div>
		{/each}
	</Card>
{/if}

<Dialog title={tr(`Stavke: ${cluster.length}`, `Items: ${cluster.length}`)} bind:open={showCluster}>
	<div class="map-grid">
		{#each cluster as id (id)}
			<button
				type="button"
				aria-label={tr('Otvori fotku', 'Open the photo')}
				onclick={() => open(id, cluster)}
			>
				<img src="/api/assets/{id}/thumbnail" alt="" loading="lazy" />
			</button>
		{/each}
	</div>
</Dialog>

{#if page.state.viewer}
	<Viewer
		id={page.state.viewer}
		onClose={() => history.back()}
		onNavigate={(photo) => replaceState('', { viewer: photo })}
		onChanged={load}
		{neighbours}
	/>
{/if}
