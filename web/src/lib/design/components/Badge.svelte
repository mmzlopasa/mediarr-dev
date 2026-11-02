<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		kind = 'mute',
		children
	}: { kind?: 'mute' | 'ok' | 'warn' | 'bad' | 'acc'; children: Snippet } = $props();
</script>

<span class="badge {kind}">{@render children()}</span>
