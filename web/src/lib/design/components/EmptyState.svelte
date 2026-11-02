<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { IconName } from '../icons';
	import Icon from './Icon.svelte';

	let { icon, text, cta }: { icon: IconName; text: string; cta?: Snippet } = $props();
</script>

<div class="empty">
	<span class="ic lg"><Icon name={icon} size={26} /></span>
	<p>{text}</p>
	{#if cta}{@render cta()}{/if}
</div>
