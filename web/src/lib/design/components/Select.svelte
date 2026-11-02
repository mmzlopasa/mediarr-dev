<script lang="ts">
	import type { HTMLSelectAttributes } from 'svelte/elements';

	type Props = HTMLSelectAttributes & {
		label: string;
		options: { value: string; label: string }[];
	};

	let { label, options, value = $bindable(), ...rest }: Props = $props();
</script>

<label class="f">
	<span>{label}</span>
	<select class="in" bind:value {...rest}>
		{#each options as option (option.value)}
			<option value={option.value}>{option.label}</option>
		{/each}
	</select>
</label>
