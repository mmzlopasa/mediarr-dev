<script lang="ts">
	import type { Snippet } from 'svelte';

	let { text, children }: { text: string; children: Snippet } = $props();
</script>

<span class="tip">
	{@render children()}
	<span class="tip-b" role="tooltip">{text}</span>
</span>
