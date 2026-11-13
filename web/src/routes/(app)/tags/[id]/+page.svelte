<script lang="ts">
	import { untrack } from 'svelte';
	import { goto, pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, ApiError, tagSource, type Tag } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const id = $derived(page.params.id ?? '');
	let tag = $state<Tag>();
	let gone = $state(false);
	let timeline = $state<Timeline>();

	const source = $derived(tagSource(id));

	// Read again for each tag, as when two tags were joined and the page moved to the one kept.
	$effect(() => {
		const current = id;
		let stale = false;
		untrack(() => {
			if (tag?.id !== current) tag = undefined;
			gone = false;
			renaming = false;
		});
		api
			.tags()
			.then((tags) => {
				if (stale) return;
				tag = tags.find((candidate) => candidate.id === current);
				gone = !tag;
			})
			.catch(() => {
				if (!stale) gone = true;
			});
		return () => {
			stale = true;
		};
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
				showToast('err', cause instanceof Error ? cause.message : t('tags.id.notRenamed'));
				return;
			}
			const join = confirm(t('tags.id.theTagNameAlreadyExists', { name }));
			if (!join) return;
			try {
				tag = await api.renameTag(tag.id, name, true);
			} catch (again) {
				showToast('err', again instanceof Error ? again.message : t('tags.id.notJoined'));
				return;
			}
		}
		renaming = false;
		showToast('ok', t('tags.id.renamed'));
		if (tag.id !== id)
			await goto(resolve('/(app)/tags/[id]', { id: tag.id }), { replaceState: true });
	}

	async function untag(ids: string[], clear: () => void) {
		if (!tag) return;
		try {
			const { changed } = await api.changeTag(ids, tag.name, true);
			showToast('ok', t('tags.id.tagRemovedChanged', { changed }));
			clear();
			await timeline?.reloadLoaded();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{tag?.name ?? t('tags.id.tag')} — Mediarr</title></svelte:head>

{#if gone}
	<Alert kind="err">{t('tags.id.thisTagDoesNotExist')}</Alert>
{:else if !tag}
	<Skeleton height="220px" />
{:else}
	<div class="ph">
		{#if renaming}
			<form class="tag-rename" onsubmit={rename} aria-label={t('tags.id.renameTheTag')}>
				<input class="in" bind:value={newName} maxlength="100" aria-label={t('tags.id.newName')} />
				<Button type="submit" variant="gold" small>{t('common.save')}</Button>
				<Button small onclick={() => (renaming = false)}>{t('common.cancel')}</Button>
			</form>
		{:else}
			<div><h1>{tag.name}</h1></div>
			<Button small onclick={startRename}>{t('tags.id.rename')}</Button>
		{/if}
	</div>
	<Timeline
		bind:this={timeline}
		{source}
		hrefFor={(photo) => resolve('/(app)/photos/[id]', { id: photo })}
		onOpen={(photo) => pushState('', { viewer: photo })}
	>
		{#snippet selectionActions(ids, clear)}
			<button
				type="button"
				class="icon-btn"
				aria-label={t('tags.id.removeTheTag')}
				title={t('tags.id.removeTheTag')}
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
