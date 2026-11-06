<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		title,
		id,
		note,
		actions,
		children
	}: { title: string; id?: string; note?: string; actions?: Snippet; children: Snippet } = $props();
</script>

<section class="card glass" {id}>
	<header class="card-h">
		<div class="card-t">
			<h2>{title}</h2>
			{#if note}<p class="card-note">{note}</p>{/if}
		</div>
		{#if actions}<div class="card-a">{@render actions()}</div>{/if}
	</header>
	<div class="card-b">{@render children()}</div>
</section>
