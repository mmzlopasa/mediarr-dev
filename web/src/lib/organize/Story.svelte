<script lang="ts">
	import { kenBurns } from '#lib/motion/actions.ts';
	import { preferences } from '#lib/preferences.svelte.ts';
	import { onMount } from 'svelte';
	import { api, type Memory, type StoryExport } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	const pictureMs = (preferences()?.memorySeconds ?? 4) * 1000;
	const EXPORT_POLL_MS = 2000;

	let { memory, title, onClose }: { memory: Memory; title: string; onClose: () => void } = $props();

	let index = $state(0);
	let paused = $state(false);
	let exported = $state<StoryExport>();
	let dialog = $state<HTMLDivElement>();

	const items = $derived(memory.items);

	onMount(() => {
		dialog?.focus();
		const timer = setInterval(() => {
			if (!paused) index = index + 1 < items.length ? index + 1 : 0;
		}, pictureMs);
		return () => clearInterval(timer);
	});

	function move(step: number) {
		index = (index + step + items.length) % items.length;
	}

	function onKey(event: KeyboardEvent) {
		if (event.key === 'Escape') onClose();
		else if (event.key === 'ArrowLeft') move(-1);
		else if (event.key === 'ArrowRight') move(1);
		else if (event.key === ' ') paused = !paused;
	}

	async function exportVideo() {
		try {
			exported = await api.createStory(
				title,
				items.map((item) => item.id)
			);
			while (exported.status === 'working') {
				await new Promise((resolve) => setTimeout(resolve, EXPORT_POLL_MS));
				exported = await api.story(exported.id);
			}
			if (exported.status === 'failed') {
				showToast('err', t('story.theVideoCouldNotBe'));
			}
		} catch {
			exported = undefined;
			showToast('err', t('story.theVideoCouldNotBe'));
		}
	}
</script>

<!-- eslint-disable svelte/no-navigation-without-resolve -- the video is an API file, not a page -->
<svelte:window onkeydown={onKey} />

<div
	class="story"
	role="dialog"
	aria-modal="true"
	aria-label={title}
	tabindex="-1"
	bind:this={dialog}
>
	<div class="story-bar">
		<span style="width:{((index + 1) / items.length) * 100}%"></span>
	</div>
	<div class="story-top">
		<button type="button" class="icon-btn" aria-label={t('common.close')} onclick={onClose}
			><Icon name="back" /></button
		>
		<b>{title}</b>
		<button
			type="button"
			class="icon-btn"
			aria-pressed={paused}
			aria-label={paused ? t('common.resume') : t('story.pause')}
			onclick={() => (paused = !paused)}><Icon name="play" /></button
		>
		{#if exported?.status === 'ready'}
			<a class="btn gold sm" href="/api/stories/{exported.id}/video" download data-sveltekit-reload>
				<Icon name="download" size={14} />
				{t('story.downloadTheVideo')}
			</a>
		{:else if exported?.status === 'working'}
			<Button small disabled>{t('story.makingTheVideo')}</Button>
		{:else}
			<Button small onclick={exportVideo}>{t('story.makeAVideo')}</Button>
		{/if}
	</div>
	<div class="story-stage">
		{#key items[index].id}
			<img
				src="/api/assets/{items[index].id}/thumbnail?size=large"
				alt=""
				use:kenBurns={{ seconds: pictureMs / 1000, turn: index }}
			/>
		{/key}
		<button
			type="button"
			class="icon-btn viewer-nav viewer-prev"
			aria-label={t('story.previous')}
			onclick={() => move(-1)}><Icon name="back" /></button
		>
		<button
			type="button"
			class="icon-btn viewer-nav viewer-next"
			aria-label={t('story.next')}
			onclick={() => move(1)}><Icon name="forward" /></button
		>
	</div>
</div>
