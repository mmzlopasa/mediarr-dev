<script lang="ts">
	import type { Snippet } from 'svelte';
	import Dialog from './Dialog.svelte';

	let {
		title,
		open = $bindable(false),
		children
	}: { title: string; open?: boolean; children: Snippet } = $props();
</script>

<Dialog {title} sheet bind:open>{@render children()}</Dialog>
