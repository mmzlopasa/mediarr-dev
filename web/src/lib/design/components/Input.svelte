<script lang="ts">
	import type { HTMLInputAttributes } from 'svelte/elements';

	type Props = HTMLInputAttributes & { label: string; hint?: string };

	let { label, hint, value = $bindable(), ...rest }: Props = $props();
</script>

<label class="f">
	<span>{label}</span>
	<input class="in" bind:value {...rest} />
	{#if hint}<small class="hint">{hint}</small>{/if}
</label>
