<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { api, type Album, type Person, type SearchOptions } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	/** Every filter of a search, to choose from what this library has. */
	let {
		params,
		onApply,
		onClose
	}: {
		params: URLSearchParams;
		onApply: (next: URLSearchParams) => void;
		onClose: () => void;
	} = $props();

	let options = $state<SearchOptions>({ cameras: [], lenses: [], places: [], tags: [] });
	let people = $state<Person[]>([]);
	let albums = $state<Album[]>([]);

	// The form starts from the search on screen, once: the panel opens anew for each change.
	const start = untrack(() => params);
	let from = $state(start.get('from') ?? '');
	let to = $state(start.get('to') ?? '');
	let chosenPeople = $state<string[]>(start.getAll('person'));
	let anyPerson = $state(start.get('people') === 'any');
	let place = $state(start.get('place') ?? '');
	let camera = $state(start.get('camera') ?? '');
	let lens = $state(start.get('lens') ?? '');
	let kind = $state(start.get('type') ?? '');
	let minRating = $state(start.get('minRating') ?? '');
	let pick = $state(start.get('pick') ?? '');
	let tags = $state<string[]>(start.getAll('tag').map((tag) => tag.toLowerCase()));
	let album = $state(start.get('notInAlbum') === 'true' ? 'none' : (start.get('album') ?? ''));
	let favorite = $state(start.get('favorite') === 'true');

	onMount(() => {
		api
			.searchOptions()
			.then((found) => (options = found))
			.catch(() => undefined);
		api
			.people()
			.then((found) => (people = found.people.filter((person) => person.name && !person.hidden)))
			.catch(() => undefined);
		api
			.albums('title')
			.then((found) => (albums = found))
			.catch(() => undefined);
	});

	function toggle(list: string[], value: string) {
		return list.includes(value) ? list.filter((entry) => entry !== value) : [...list, value];
	}

	function apply(event: SubmitEvent) {
		event.preventDefault();
		// eslint-disable-next-line svelte/prefer-svelte-reactivity -- a new address, built once
		const next = new URLSearchParams();
		const q = params.get('q');
		if (q) next.set('q', q);
		if (params.get('plain')) next.set('plain', 'true');
		if (from) next.set('from', from);
		if (to) next.set('to', to);
		for (const person of chosenPeople) next.append('person', person);
		if (anyPerson && chosenPeople.length > 1) next.set('people', 'any');
		for (const [key, value] of [
			['place', place],
			['camera', camera],
			['lens', lens],
			['type', kind],
			['minRating', minRating],
			['pick', pick]
		]) {
			if (value.trim()) next.set(key, value.trim());
		}
		for (const tag of tags) next.append('tag', tag);
		if (album === 'none') next.set('notInAlbum', 'true');
		else if (album) next.set('album', album);
		if (favorite) next.set('favorite', 'true');
		onApply(next);
	}

	function clear() {
		// eslint-disable-next-line svelte/prefer-svelte-reactivity -- a new address, built once
		const next = new URLSearchParams();
		const q = params.get('q');
		if (q) next.set('q', q);
		onApply(next);
	}
</script>

<form class="sf" onsubmit={apply} aria-label={t('filterPanel.filters')}>
	<div class="sf-grid">
		<fieldset class="sf-field">
			<legend>{t('filterPanel.date')}</legend>
			<div class="sf-row">
				<input class="in" type="date" bind:value={from} aria-label={t('filterPanel.from')} />
				<span aria-hidden="true">–</span>
				<input class="in" type="date" bind:value={to} aria-label={t('filterPanel.to')} />
			</div>
		</fieldset>

		<fieldset class="sf-field">
			<legend>{t('filterPanel.type')}</legend>
			<div class="seg" role="radiogroup">
				{#each [['', t('filterPanel.all')], ['photo', t('common.photos')], ['video', t('common.videos')]] as [value, label] (value)}
					<label class:on={kind === value}
						><input type="radio" bind:group={kind} {value} />{label}</label
					>
				{/each}
			</div>
		</fieldset>

		{#if people.length}
			<fieldset class="sf-field sf-wide">
				<legend>{t('filterPanel.people')}</legend>
				<div class="sf-chips">
					{#each people as person (person.id)}
						<label class="sf-chip" class:on={chosenPeople.includes(person.id)}>
							<input
								type="checkbox"
								checked={chosenPeople.includes(person.id)}
								onchange={() => (chosenPeople = toggle(chosenPeople, person.id))}
							/>{person.name}
						</label>
					{/each}
				</div>
				{#if chosenPeople.length > 1}
					<label class="sf-check">
						<input type="checkbox" bind:checked={anyPerson} />
						{t('filterPanel.anyOfThemNotAll')}
					</label>
				{/if}
			</fieldset>
		{/if}

		<label class="sf-field">
			<span>{t('common.place')}</span>
			<input class="in" list="sf-places" bind:value={place} />
			<datalist id="sf-places"
				>{#each options.places as value (value)}<option {value}></option>{/each}</datalist
			>
		</label>
		<label class="sf-field">
			<span>{t('common.camera')}</span>
			<input class="in" list="sf-cameras" bind:value={camera} />
			<datalist id="sf-cameras"
				>{#each options.cameras as value (value)}<option {value}></option>{/each}</datalist
			>
		</label>
		<label class="sf-field">
			<span>{t('filterPanel.lens')}</span>
			<input class="in" list="sf-lenses" bind:value={lens} />
			<datalist id="sf-lenses"
				>{#each options.lenses as value (value)}<option {value}></option>{/each}</datalist
			>
		</label>
		<label class="sf-field">
			<span>{t('filterPanel.rating')}</span>
			<select class="in" bind:value={minRating}>
				<option value="">{t('filterPanel.any')}</option>
				{#each [1, 2, 3, 4, 5] as stars (stars)}
					<option value={String(stars)}>{'★'.repeat(stars)}{stars < 5 ? '+' : ''}</option>
				{/each}
			</select>
		</label>
		<label class="sf-field">
			<span>{t('cull.mark')}</span>
			<select class="in" bind:value={pick}>
				<option value="">{t('filterPanel.any')}</option>
				<option value="1">{t('cull.picks')}</option>
				<option value="-1">{t('cull.rejects')}</option>
				<option value="0">{t('cull.unmarked')}</option>
			</select>
		</label>
		<label class="sf-field">
			<span>{t('filterPanel.album')}</span>
			<select class="in" bind:value={album}>
				<option value="">{t('filterPanel.any2')}</option>
				<option value="none">{t('filterPanel.inNoAlbum')}</option>
				{#each albums as entry (entry.id)}<option value={entry.id}>{entry.title}</option>{/each}
			</select>
		</label>

		{#if options.tags.length}
			<fieldset class="sf-field sf-wide">
				<legend>{t('common.tags')}</legend>
				<div class="sf-chips">
					{#each options.tags as tag (tag)}
						<label class="sf-chip" class:on={tags.includes(tag.toLowerCase())}>
							<input
								type="checkbox"
								checked={tags.includes(tag.toLowerCase())}
								onchange={() => (tags = toggle(tags, tag.toLowerCase()))}
							/>#{tag}
						</label>
					{/each}
				</div>
			</fieldset>
		{/if}

		<label class="sf-check sf-wide">
			<input type="checkbox" bind:checked={favorite} />
			{t('filterPanel.favouritesOnly')}
		</label>
	</div>
	<div class="set-foot sf-foot">
		<Button small onclick={clear}>{t('filterPanel.clear')}</Button>
		<Button small onclick={onClose}>{t('common.close')}</Button>
		<Button type="submit" variant="gold" small>{t('filterPanel.apply')}</Button>
	</div>
</form>
