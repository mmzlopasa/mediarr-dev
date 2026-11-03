<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AlbumRules, type Person, type Tag } from '#lib/api.ts';
	import Input from '#lib/design/components/Input.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let { rules = $bindable({}) }: { rules?: AlbumRules } = $props();

	let cameras = $state<string[]>([]);
	let from = $state(rules.from ?? '');
	let to = $state(rules.to ?? '');
	let kind = $state<string>(rules.kind ?? '');
	let camera = $state(rules.camera ?? '');
	let person = $state(rules.person ?? '');
	let tag = $state(rules.tag ?? '');
	let place = $state(rules.place ?? '');
	let people = $state<Person[]>([]);
	let tags = $state<Tag[]>([]);

	onMount(async () => {
		cameras = await api.cameras().catch(() => []);
		people = (await api.people().catch(() => ({ people: [] as Person[] }))).people.filter(
			(entry) => entry.name
		);
		tags = await api.tags().catch(() => []);
	});

	$effect(() => {
		rules = {
			from: from || undefined,
			to: to || undefined,
			kind: (kind || undefined) as AlbumRules['kind'],
			camera: camera || undefined,
			person: person || undefined,
			tag: tag || undefined,
			place: place || undefined
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
<Select
	label={tr('Osoba', 'Person')}
	bind:value={person}
	options={[
		{ value: '', label: tr('Sve', 'All') },
		...people.map((entry) => ({ value: entry.id, label: entry.name }))
	]}
/>
<Select
	label={tr('Oznaka', 'Tag')}
	bind:value={tag}
	options={[
		{ value: '', label: tr('Sve', 'All') },
		...tags.map((entry) => ({ value: entry.id, label: entry.name }))
	]}
/>
<Input
	label={tr('Mjesto', 'Place')}
	hint={tr('Grad, regija ili država', 'A city, region or country')}
	bind:value={place}
/>
