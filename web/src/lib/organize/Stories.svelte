<script lang="ts">
	import { onMount } from 'svelte';
	import { memoryTitle } from '#lib/organize/memories.ts';
	import Story from '#lib/organize/Story.svelte';
	import { api, type Memory } from '#lib/api.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { yearsAgo } from '#lib/organize/stories.ts';

	let memories = $state<Memory[]>([]);
	let open = $state<Memory>();

	onMount(async () => {
		const now = new Date();
		const pad = (value: number) => String(value).padStart(2, '0');
		const today = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
		try {
			memories = (await api.memories(today)).filter((memory) => memory.items.length > 0);
		} catch {
			// The timeline below reports a server that does not answer.
		}
	});

	function label(memory: Memory) {
		if (memory.kind === 'week') return tr('Protekli tjedan', 'The last week');
		const years = yearsAgo(memory.year ?? 0, new Date().getFullYear());
		return tr(`Prije ${years} god.`, years === 1 ? '1 year ago' : `${years} years ago`);
	}
</script>

{#if memories.length > 0}
	<!-- Memories as stories: a row of tall cards, each plays as a story where it is. -->
	<div class="stories" aria-label={tr('Uspomene', 'Memories')} role="group">
		{#each memories as memory (memory.kind + memory.title)}
			<button type="button" class="story-tile" onclick={() => (open = memory)}>
				<img src="/api/assets/{memory.items[0].id}/thumbnail" alt="" loading="lazy" />
				<span class="story-tile-t">
					<b>{label(memory)}</b>
					<small
						>{tr(
							`${memory.items.length} stavki`,
							memory.items.length === 1 ? '1 item' : `${memory.items.length} items`
						)}</small
					>
				</span>
			</button>
		{/each}
	</div>
{/if}

{#if open}
	<Story memory={open} title={memoryTitle(open)} onClose={() => (open = undefined)} />
{/if}
