<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AlbumRules, type Person, type Tag } from '#lib/api.ts';
	import Input from '#lib/design/components/Input.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import { t } from '#lib/i18n.svelte.ts';

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

<Input label={t('common.fromDate')} type="date" bind:value={from} />
<Input label={t('common.toDate')} type="date" bind:value={to} />
<Select
	label={t('rulesForm.kind')}
	bind:value={kind}
	options={[
		{ value: '', label: t('rulesForm.all') },
		{ value: 'photo', label: t('common.photos') },
		{ value: 'video', label: t('common.videos') },
		{ value: 'live', label: 'Live Photo' }
	]}
/>
<Select
	label={t('common.camera')}
	bind:value={camera}
	options={[
		{ value: '', label: t('rulesForm.all') },
		...cameras.map((name) => ({ value: name, label: name }))
	]}
/>
<Select
	label={t('rulesForm.person')}
	bind:value={person}
	options={[
		{ value: '', label: t('rulesForm.all') },
		...people.map((entry) => ({ value: entry.id, label: entry.name }))
	]}
/>
<Select
	label={t('rulesForm.tag')}
	bind:value={tag}
	options={[
		{ value: '', label: t('rulesForm.all') },
		...tags.map((entry) => ({ value: entry.id, label: entry.name }))
	]}
/>
<Input label={t('common.place')} hint={t('rulesForm.aCityRegionOrCountry')} bind:value={place} />
