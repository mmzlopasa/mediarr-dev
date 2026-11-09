<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type Tag } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let tags = $state<Tag[]>();
	let failed = $state(false);

	async function load() {
		try {
			tags = await api.tags();
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(load);

	async function remove(tag: Tag) {
		try {
			await api.deleteTag(tag.id);
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t('common.tags')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t('common.tags')}</h1></div></div>

{#if failed}
	<Alert kind="err">{t('tags.tagsCouldNotBeLoaded')}</Alert>
{:else if !tags}
	<Skeleton height="120px" />
{:else}
	<section class="card glass">
		<div class="card-b">
			{#each tags as tag (tag.id)}
				<div class="alb-list">
					<b><a href={resolve('/(app)/tags/[id]', { id: tag.id })}>{tag.name}</a></b>
					<span class="alb-meta">{tag.assetCount}</span>
					<Button small onclick={() => remove(tag)}>{t('common.delete')}</Button>
				</div>
			{:else}
				<EmptyState icon="list" text={t('tags.noTagsYetSelectItems')} />
			{/each}
		</div>
	</section>
{/if}
