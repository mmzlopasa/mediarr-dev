<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';
	import Button from './Button.svelte';

	let {
		total,
		perPage,
		page = $bindable()
	}: { total: number; perPage: number; page: number } = $props();

	const pages = $derived(Math.max(1, Math.ceil(total / perPage)));
	const visible = $derived.by(() => {
		const out = [];
		for (let i = Math.max(1, page - 2); i <= Math.min(pages, page + 2); i++) out.push(i);
		return out;
	});
</script>

{#if pages > 1}
	<nav class="pager" aria-label={tr('Stranice', 'Pages')}>
		{#if page > 1}<Button small aria-label="←" onclick={() => (page -= 1)}>←</Button>{/if}
		{#each visible as number (number)}
			<Button
				small
				variant={number === page ? 'gold' : 'default'}
				aria-current={number === page ? 'page' : undefined}
				onclick={() => (page = number)}>{number}</Button
			>
		{/each}
		{#if page < pages}<Button small aria-label="→" onclick={() => (page += 1)}>→</Button>{/if}
		<span class="mute sm-t">{tr(`ukupno ${total}`, `${total} total`)}</span>
	</nav>
{/if}
