<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AlbumRules } from '#lib/api.ts';
	import Input from '#lib/design/components/Input.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let { rules = $bindable({}) }: { rules?: AlbumRules } = $props();

	let cameras = $state<string[]>([]);
	let from = $state(rules.from ?? '');
	let to = $state(rules.to ?? '');
	let kind = $state<string>(rules.kind ?? '');
	let camera = $state(rules.camera ?? '');

	onMount(async () => {
		cameras = await api.cameras().catch(() => []);
	});

	$effect(() => {
		rules = {
			from: from || undefined,
			to: to || undefined,
			kind: (kind || undefined) as AlbumRules['kind'],
			camera: camera || undefined
		};
	});
</script>

<Input label={tr('Od datuma', 'From date')} type="date" bind:value={from} />
<Input label={tr('Do datuma', 'To date')} type="date" bind:value={to} />
<Select
	label={tr('Vrsta', 'Kind')}
	bind:value={kind}
	options={[
		{ value: '', label: tr('Sve', 'All') },
		{ value: 'photo', label: tr('Fotke', 'Photos') },
		{ value: 'video', label: tr('Videi', 'Videos') },
		{ value: 'live', label: 'Live Photo' }
	]}
/>
<Select
	label={tr('Kamera', 'Camera')}
	bind:value={camera}
	options={[
		{ value: '', label: tr('Sve', 'All') },
		...cameras.map((name) => ({ value: name, label: name }))
	]}
/>
<p class="alb-meta">
	{tr(
		'Pravila za osobe, mjesta i oznake još nisu dostupna: stižu s tim značajkama.',
		'Rules for people, places and tags are not available yet: they arrive with those features.'
	)}
</p>
