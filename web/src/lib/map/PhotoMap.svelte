<script lang="ts">
	import 'maplibre-gl/dist/maplibre-gl.css';
	import { onMount } from 'svelte';
	import {
		addProtocol,
		LngLatBounds,
		Map as MapView,
		NavigationControl,
		removeProtocol,
		setWorkerUrl,
		type GeoJSONSource
	} from 'maplibre-gl';
	// Named here, because a build does not find the worker by itself and the map would stay empty.
	import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?url';
	import { Protocol } from 'pmtiles';
	import type { MapPoints } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	const FIT_PADDING = 48;
	const FIT_MAX_ZOOM = 12;
	const CLUSTER_RADIUS = 50;
	const LEAF_LIMIT = 200;

	let {
		points,
		styleUrl,
		heatmap,
		focus,
		onPhoto,
		onCluster
	}: {
		points: MapPoints;
		styleUrl: string;
		heatmap: boolean;
		focus?: { lat: number; lon: number };
		onPhoto: (id: string) => void;
		onCluster: (ids: string[]) => void;
	} = $props();

	let container = $state<HTMLDivElement>();
	let map = $state<MapView>();
	let ready = $state(false);
	let noBackground = $state(false);
	let noWebgl = $state(false);

	const blankStyle = { version: 8 as const, sources: {}, layers: [] };

	function geojson(data: MapPoints) {
		return {
			type: 'FeatureCollection' as const,
			features: data.ids.map((id, index) => ({
				type: 'Feature' as const,
				properties: { id },
				geometry: {
					type: 'Point' as const,
					coordinates: [data.lons[index], data.lats[index]]
				}
			}))
		};
	}

	function fit(data: MapPoints) {
		if (!map || data.ids.length === 0) return;
		const bounds = new LngLatBounds();
		data.ids.forEach((_, index) => bounds.extend([data.lons[index], data.lats[index]]));
		map.fitBounds(bounds, { padding: FIT_PADDING, maxZoom: FIT_MAX_ZOOM, duration: 0 });
	}

	function addLayers(view: MapView) {
		// The design's one accent, read from the page so both themes agree.
		const gold =
			getComputedStyle(document.documentElement).getPropertyValue('--acc').trim() || '#c4bbff';
		view.addSource('photos', {
			type: 'geojson',
			data: geojson(points),
			cluster: true,
			clusterRadius: CLUSTER_RADIUS
		});
		view.addSource('photos-all', { type: 'geojson', data: geojson(points) });
		view.addLayer({
			id: 'heat',
			type: 'heatmap',
			source: 'photos-all',
			layout: { visibility: heatmap ? 'visible' : 'none' },
			paint: { 'heatmap-radius': 24, 'heatmap-opacity': 0.8 }
		});
		view.addLayer({
			id: 'clusters',
			type: 'circle',
			source: 'photos',
			filter: ['has', 'point_count'],
			paint: {
				'circle-color': gold,
				'circle-opacity': 0.85,
				'circle-stroke-width': 2,
				'circle-stroke-color': '#1a1a1a',
				'circle-radius': ['step', ['get', 'point_count'], 14, 10, 18, 100, 24, 1000, 30]
			}
		});
		if (view.getStyle().glyphs) {
			view.addLayer({
				id: 'cluster-count',
				type: 'symbol',
				source: 'photos',
				filter: ['has', 'point_count'],
				layout: {
					'text-field': ['get', 'point_count_abbreviated'],
					'text-font': ['Noto Sans Medium'],
					'text-size': 12
				},
				paint: { 'text-color': '#1a1a1a' }
			});
		}
		view.addLayer({
			id: 'photo',
			type: 'circle',
			source: 'photos',
			filter: ['!', ['has', 'point_count']],
			paint: {
				'circle-color': gold,
				'circle-radius': 7,
				'circle-stroke-width': 2,
				'circle-stroke-color': '#1a1a1a'
			}
		});
		view.on('click', 'photo', (event) => {
			const id = event.features?.[0]?.properties?.id;
			if (id) onPhoto(String(id));
		});
		view.on('click', 'clusters', async (event) => {
			const cluster = event.features?.[0];
			const clusterId = cluster?.properties?.cluster_id;
			if (clusterId === undefined) return;
			const source = view.getSource('photos') as GeoJSONSource;
			const leaves = await source.getClusterLeaves(clusterId, LEAF_LIMIT, 0);
			onCluster(leaves.map((leaf) => String(leaf.properties?.id)));
		});
		for (const layer of ['photo', 'clusters']) {
			view.on('mouseenter', layer, () => (view.getCanvas().style.cursor = 'pointer'));
			view.on('mouseleave', layer, () => (view.getCanvas().style.cursor = ''));
		}
	}

	onMount(() => {
		setWorkerUrl(workerUrl);
		const protocol = new Protocol();
		addProtocol('pmtiles', protocol.tile);
		let view: MapView | undefined;
		let cancelled = false;
		(async () => {
			// Without the style there is no background, and the photos are still shown.
			let style: string | typeof blankStyle = styleUrl;
			try {
				const response = await fetch(styleUrl);
				if (!response.ok) throw new Error(String(response.status));
			} catch {
				style = blankStyle;
				noBackground = true;
			}
			if (cancelled || !container) return;
			let created: MapView;
			try {
				created = new MapView({
					container,
					style,
					attributionControl: { compact: true, customAttribution: 'Places: GeoNames' }
				});
			} catch {
				noWebgl = true;
				return;
			}
			view = created;
			created.addControl(new NavigationControl({ showCompass: false }));
			created.on('load', () => {
				map = created;
				addLayers(created);
				fit(points);
				ready = true;
			});
		})();
		return () => {
			cancelled = true;
			view?.remove();
			removeProtocol('pmtiles');
		};
	});

	$effect(() => {
		const data = points;
		if (!ready || !map) return;
		(map.getSource('photos') as GeoJSONSource).setData(geojson(data));
		(map.getSource('photos-all') as GeoJSONSource).setData(geojson(data));
	});

	$effect(() => {
		if (ready) map?.setLayoutProperty('heat', 'visibility', heatmap ? 'visible' : 'none');
	});

	$effect(() => {
		if (ready && focus) map?.flyTo({ center: [focus.lon, focus.lat], zoom: 9 });
	});
</script>

{#if noBackground}
	<Alert kind="warn">
		{tr(
			'Podloga karte nije dostupna, ali fotke su prikazane. Administrator je može promijeniti u postavkama.',
			'The map background is not available, but your photos are shown. An administrator can change it in the settings.'
		)}
	</Alert>
{/if}
{#if noWebgl}
	<Alert kind="err"
		>{tr('Ovaj preglednik ne može prikazati kartu.', 'This browser cannot show the map.')}</Alert
	>
{/if}
<div class="map-box"><div class="map-canvas" bind:this={container}></div></div>
