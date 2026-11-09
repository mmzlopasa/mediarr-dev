<script lang="ts">
	import { api, type AlbumPrivacy, type PeopleList } from '#lib/api.ts';
	import Avatar from '#lib/design/components/Avatar.svelte';
	import Checkbox from '#lib/design/components/Checkbox.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import { togglePerson, type PrivacyOptions } from './linkPrivacy.ts';

	let { albumId, options = $bindable() }: { albumId: string; options: PrivacyOptions } = $props();

	let facts = $state<AlbumPrivacy>();
	let factsFailed = $state(false);
	let people = $state<PeopleList>();
	let peopleFailed = $state(false);

	const hiding = $derived(options.hideFaces !== 'none');
	const choosing = $derived(options.hideFaces === 'except');
	// Only people with a name can be told apart in a list; the rest stay hidden.
	const named = $derived((people?.people ?? []).filter((person) => person.name && !person.hidden));

	$effect(() => {
		if (!hiding || facts || factsFailed) return;
		api
			.albumPrivacy(albumId)
			.then((value) => (facts = value))
			.catch(() => (factsFailed = true));
	});

	$effect(() => {
		if (!choosing || people || peopleFailed) return;
		api
			.people()
			.then((value) => (people = value))
			.catch(() => (peopleFailed = true));
	});

	const initials = (name: string) =>
		name
			.split(/\s+/)
			.map((part) => part[0] ?? '')
			.join('')
			.slice(0, 2)
			.toUpperCase();
</script>

<div class="lp">
	<Checkbox label={t('linksDialog.showLocation')} bind:checked={options.showLocation} />
	<Select
		label={t('linkPrivacy.hideFaces')}
		options={[
			{ value: 'none', label: t('linkPrivacy.none') },
			{ value: 'all', label: t('linkPrivacy.allFaces') },
			{ value: 'except', label: t('linkPrivacy.allButChosenPeople') }
		]}
		bind:value={options.hideFaces}
	/>
	{#if hiding}
		<div class="lp-facts" aria-live="polite">
			{#if factsFailed}
				<small class="hint">{t('common.thisCouldNotBeLoaded')}</small>
			{:else if !facts}
				<Skeleton height="36px" />
			{:else}
				<small class="hint">
					{facts.unchecked > 0
						? t('linkPrivacy.uncheckedPhotos', { unchecked: facts.unchecked, photos: facts.photos })
						: t('linkPrivacy.allPhotosChecked')}
					{t('linkPrivacy.missedFacesStayVisible')}
				</small>
				{#if facts.videos > 0}
					<small class="hint">{t('linkPrivacy.videosShowAsAStill', { videos: facts.videos })}</small
					>
				{/if}
			{/if}
		</div>
	{/if}
	{#if choosing}
		<fieldset class="lp-people">
			<legend>{t('linkPrivacy.peopleWhoStayVisible')}</legend>
			{#if peopleFailed}
				<small class="hint">{t('common.thisCouldNotBeLoaded')}</small>
			{:else if !people}
				<Skeleton height="44px" />
			{:else if !people.enabled}
				<small class="hint">{t('linkPrivacy.faceRecognitionIsOff')}</small>
			{:else if named.length === 0}
				<small class="hint">{t('linkPrivacy.nameSomeoneOnThePeople')}</small>
			{:else}
				<div class="lp-people-list">
					{#each named as person (person.id)}
						<label class="chk lp-person">
							<input
								type="checkbox"
								checked={options.visiblePeople.includes(person.id)}
								onchange={(event) =>
									(options.visiblePeople = togglePerson(
										options.visiblePeople,
										person.id,
										event.currentTarget.checked
									))}
							/>
							<Avatar initials={initials(person.name)} src="/api/people/{person.id}/thumbnail" />
							<span>{person.name}</span>
						</label>
					{/each}
				</div>
			{/if}
		</fieldset>
	{/if}
	<Checkbox label={t('linkPrivacy.removeCameraDetails')} bind:checked={options.stripCamera} />
	<small class="hint">{t('linkPrivacy.downloadsCarryNoCamera')}</small>
	<Checkbox label={t('linkPrivacy.removeTheDateToo')} bind:checked={options.stripDate} />
	<Checkbox label={t('linkPrivacy.askForAName')} bind:checked={options.askName} />
</div>
