<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, personSource, type Person } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const id = $derived(page.params.id ?? '');
	let person = $state<Person>();
	let others = $state<Person[]>([]);
	let gone = $state(false);
	let name = $state('');
	let born = $state('');
	let merging = $state(false);
	let timeline = $state<Timeline>();

	async function load() {
		try {
			const { people } = await api.people();
			person = people.find((candidate) => candidate.id === id);
			others = people.filter((candidate) => candidate.id !== id);
			gone = !person;
			if (person) {
				name = person.name;
				born = person.birthDate ?? '';
			}
		} catch {
			gone = true;
		}
	}

	onMount(load);

	async function save(event: SubmitEvent) {
		event.preventDefault();
		try {
			await api.updatePerson(id, { name, birthDate: born });
			showToast('ok', t('common.saved'));
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function hide() {
		try {
			await api.updatePerson(id, { hidden: true });
			await goto(resolve('/(app)/people'));
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function merge(other: Person) {
		try {
			await api.mergePeople(id, [other.id]);
			merging = false;
			showToast('ok', t('people.id.merged'));
			await load();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{person?.name || t('people.id.person')} — Mediarr</title></svelte:head>

{#if gone}
	<Alert kind="err">{t('people.id.thisPersonIsNotAvailable')}</Alert>
{:else if !person}
	<Skeleton height="220px" />
{:else}
	<div class="ph">
		<div>
			<h1>{person.name || t('common.noName')}</h1>
			<p>{person.assetCount}</p>
		</div>
		<div class="ph-a">
			<Button small onclick={() => (merging = true)}>{t('people.id.mergeWith')}</Button>
			<Button small onclick={hide}>{t('common.hide')}</Button>
		</div>
	</div>
	<form class="map-bar" onsubmit={save}>
		<Input label={t('common.name2')} maxlength={100} bind:value={name} />
		<Input label={t('people.id.dateOfBirth')} type="date" bind:value={born} />
		<Button type="submit" small variant="gold">{t('common.save')}</Button>
	</form>
	<Timeline
		bind:this={timeline}
		source={personSource(id)}
		hrefFor={(photo) => resolve('/(app)/photos/[id]', { id: photo })}
		onOpen={(photo) => pushState('', { viewer: photo })}
	/>
	{#if page.state.viewer}
		<Viewer
			id={page.state.viewer}
			onClose={() => history.back()}
			onNavigate={(photo) => replaceState('', { viewer: photo })}
			onChanged={() => timeline?.reloadLoaded()}
			neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
			strip={(photo) => timeline?.around(photo) ?? []}
			playlist={(photo) => timeline?.playlist(photo) ?? Promise.resolve([])}
		/>
	{/if}
	<Dialog title={t('people.id.mergeWith')} bind:open={merging}>
		{#each others as other (other.id)}
			<div class="alb-list">
				<b>{other.name || t('common.noName')} · {other.assetCount}</b>
				<Button small onclick={() => merge(other)}>{t('people.id.merge')}</Button>
			</div>
		{:else}
			<p class="alb-meta">{t('people.id.thereIsNobodyElse')}</p>
		{/each}
	</Dialog>
{/if}
