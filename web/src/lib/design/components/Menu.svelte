<script lang="ts">
	import type { Snippet } from 'svelte';

	let { label, children }: { label: string; children: Snippet } = $props();
</script>

<details class="dd">
	<summary class="btn sm">{label}</summary>
	<div class="dd-p glass">{@render children()}</div>
</details>
