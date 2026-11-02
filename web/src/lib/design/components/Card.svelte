<script lang="ts">
	import type { Snippet } from 'svelte';

	let { title, actions, children }: { title: string; actions?: Snippet; children: Snippet } =
		$props();
</script>

<section class="card glass">
	<header class="card-h">
		<h2>{title}</h2>
		{#if actions}<div class="card-a">{@render actions()}</div>{/if}
	</header>
	<div class="card-b">{@render children()}</div>
</section>
