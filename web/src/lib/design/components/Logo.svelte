<script lang="ts">
	import { resolve } from '$app/paths';
	import Brand from './Brand.svelte';

	let { tag }: { tag?: string } = $props();
</script>

<a class="logo" href={resolve('/(app)')} aria-label="Mediarr">
	<Brand />
	{#if tag}<span class="logo-tag">{tag}</span>{/if}
</a>
