<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, ApiError, tagSource, type Tag } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const id = $derived(page.params.id ?? '');
	let tag = $state<Tag>();
	let gone = $state(false);
	let timeline = $state<Timeline>();

	onMount(async () => {
		try {
			tag = (await api.tags()).find((candidate) => candidate.id === id);
			gone = !tag;
		} catch {
			gone = true;
		}
	});

	let renaming = $state(false);
	let newName = $state('');

	function startRename() {
		newName = tag?.name ?? '';
		renaming = true;
	}

	async function rename(event: SubmitEvent) {
		event.preventDefault();
		if (!tag) return;
		const name = newName.trim();
		if (!name || name === tag.name) {
			renaming = false;
			return;
		}
		try {
			tag = await api.renameTag(tag.id, name);
		} catch (cause) {
			if (!(cause instanceof ApiError && cause.status === 409)) {
				showToast(
					'err',
					cause instanceof Error ? cause.message : tr('Nije preimenovano.', 'Not renamed.')
				);
				return;
			}
			const join = confirm(
				tr(
					`Oznaka „${name}” već postoji. Spojiti ih? Sve fotke će imati oznaku „${name}”.`,
					`The tag “${name}” already exists. Join them? All the photos will have “${name}”.`
				)
			);
			if (!join) return;
			try {
				tag = await api.renameTag(tag.id, name, true);
			} catch (again) {
				showToast(
					'err',
					again instanceof Error ? again.message : tr('Nije spojeno.', 'Not joined.')
				);
				return;
			}
		}
		renaming = false;
		showToast('ok', tr('Preimenovano.', 'Renamed.'));
		if (tag.id !== id)
			await goto(resolve('/(app)/tags/[id]', { id: tag.id }), { replaceState: true });
	}

	async function untag(ids: string[], clear: () => void) {
		if (!tag) return;
		try {
			const { changed } = await api.changeTag(ids, tag.name, true);
			showToast('ok', tr(`Oznaka uklonjena: ${changed}`, `Tag removed: ${changed}`));
			clear();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tag?.name ?? tr('Oznaka', 'Tag')} — Mediarr</title></svelte:head>

{#if gone}
	<Alert kind="err">{tr('Ova oznaka ne postoji.', 'This tag does not exist.')}</Alert>
{:else if !tag}
	<Skeleton height="220px" />
{:else}
	<div class="ph">
		{#if renaming}
			<form
				class="tag-rename"
				onsubmit={rename}
				aria-label={tr('Preimenuj oznaku', 'Rename the tag')}
			>
				<input
					class="in"
					bind:value={newName}
					maxlength="100"
					aria-label={tr('Novo ime', 'New name')}
				/>
				<Button type="submit" variant="gold" small>{tr('Spremi', 'Save')}</Button>
				<Button small onclick={() => (renaming = false)}>{tr('Odustani', 'Cancel')}</Button>
			</form>
		{:else}
			<div><h1>{tag.name}</h1></div>
			<Button small onclick={startRename}>{tr('Preimenuj', 'Rename')}</Button>
		{/if}
	</div>
	<Timeline
		bind:this={timeline}
		source={tagSource(id)}
		hrefFor={(photo) => resolve('/(app)/photos/[id]', { id: photo })}
		onOpen={(photo) => pushState('', { viewer: photo })}
	>
		{#snippet selectionActions(ids, clear)}
			<button
				type="button"
				class="icon-btn"
				aria-label={tr('Ukloni oznaku', 'Remove the tag')}
				title={tr('Ukloni oznaku', 'Remove the tag')}
				onclick={() => untag(ids, clear)}><Icon name="list" /></button
			>
		{/snippet}
	</Timeline>
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
{/if}
