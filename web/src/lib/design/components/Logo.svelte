<script lang="ts">
	import { resolve } from '$app/paths';

	let { tag }: { tag?: string } = $props();
</script>

<a class="logo" href={resolve('/(app)')} aria-label="Mediarr">
	<span class="logo-mark" aria-hidden="true"></span>
	<span aria-hidden="true">mediarr</span>
	{#if tag}<span class="logo-tag">{tag}</span>{/if}
</a>
