<script lang="ts">
	import type { HTMLSelectAttributes } from 'svelte/elements';

	type Props = HTMLSelectAttributes & {
		label: string;
		options: { value: string; label: string }[];
		/** The label sits inside the control, for toolbars: "Sort  Last change ▾". */
		inline?: boolean;
	};

	let { label, options, inline = false, value = $bindable(), ...rest }: Props = $props();
</script>

<label class={inline ? 'sel-inline' : 'f'}>
	<span>{label}</span>
	<select class="in" bind:value {...rest}>
		{#each options as option (option.value)}
			<option value={option.value}>{option.label}</option>
		{/each}
	</select>
</label>
