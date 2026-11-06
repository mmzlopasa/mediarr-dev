<script lang="ts">
	import Bar from './Bar.svelte';
	import { countUp } from '#lib/motion/actions.ts';

	let { label, value, sub, pct }: { label: string; value: string; sub?: string; pct?: number } =
		$props();
</script>

<div class="stat glass">
	<span class="stat-l">{label}</span>
	{#if /^\d+$/.test(value)}
		<b class="stat-v" use:countUp={{ value: Number(value) }}>{value}</b>
	{:else}
		<b class="stat-v">{value}</b>
	{/if}
	{#if sub}<span class="stat-s">{sub}</span>{/if}
	{#if pct !== undefined}<Bar {pct} />{/if}
</div>
