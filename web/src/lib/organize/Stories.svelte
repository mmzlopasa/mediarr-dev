<script lang="ts">
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';
	import { api, type Memory } from '#lib/api.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { yearsAgo } from '#lib/organize/stories.ts';

	let memories = $state<Memory[]>([]);

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
	<div class="day-strip">
		{#each memories as memory (memory.kind + memory.title)}
			<a class="day-card" href={resolve('/(app)/memories')}>
				<img src="/api/assets/{memory.items[0].id}/thumbnail" alt="" loading="lazy" />
				<span>{label(memory)}</span>
			</a>
		{/each}
	</div>
{/if}
