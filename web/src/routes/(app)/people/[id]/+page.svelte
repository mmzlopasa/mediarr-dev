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
	import { tr } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const id = $derived(page.params.id ?? '');
	let person = $state<Person>();
	let others = $state<Person[]>([]);
	let gone = $state(false);
	let name = $state('');
	let merging = $state(false);
	let timeline = $state<Timeline>();

	async function load() {
		try {
			const { people } = await api.people();
			person = people.find((candidate) => candidate.id === id);
			others = people.filter((candidate) => candidate.id !== id);
			gone = !person;
			if (person) name = person.name;
		} catch {
			gone = true;
		}
	}

	onMount(load);

	async function save(event: SubmitEvent) {
		event.preventDefault();
		try {
			await api.updatePerson(id, { name });
			showToast('ok', tr('Spremljeno.', 'Saved.'));
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function hide() {
		try {
			await api.updatePerson(id, { hidden: true });
			await goto(resolve('/(app)/people'));
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function merge(other: Person) {
		try {
			await api.mergePeople(id, [other.id]);
			merging = false;
			showToast('ok', tr('Spojeno.', 'Merged.'));
			await load();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{person?.name || tr('Osoba', 'Person')} — Mediarr</title></svelte:head>

{#if gone}
	<Alert kind="err">{tr('Ova osoba nije dostupna.', 'This person is not available.')}</Alert>
{:else if !person}
	<Skeleton height="220px" />
{:else}
	<div class="ph">
		<div>
			<h1>{person.name || tr('Bez imena', 'No name')}</h1>
			<p>{person.assetCount}</p>
		</div>
		<div class="ph-a">
			<Button small onclick={() => (merging = true)}>{tr('Spoji s…', 'Merge with…')}</Button>
			<Button small onclick={hide}>{tr('Sakrij', 'Hide')}</Button>
		</div>
	</div>
	<form class="map-bar" onsubmit={save}>
		<Input label={tr('Ime', 'Name')} maxlength={100} bind:value={name} />
		<Button type="submit" small variant="gold">{tr('Spremi', 'Save')}</Button>
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
		/>
	{/if}
	<Dialog title={tr('Spoji s…', 'Merge with…')} bind:open={merging}>
		{#each others as other (other.id)}
			<div class="alb-list">
				<b>{other.name || tr('Bez imena', 'No name')} · {other.assetCount}</b>
				<Button small onclick={() => merge(other)}>{tr('Spoji', 'Merge')}</Button>
			</div>
		{:else}
			<p class="alb-meta">{tr('Nema drugih osoba.', 'There is nobody else.')}</p>
		{/each}
	</Dialog>
{/if}
