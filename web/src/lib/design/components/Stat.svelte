<script lang="ts">
	import Bar from './Bar.svelte';

	let { label, value, sub, pct }: { label: string; value: string; sub?: string; pct?: number } =
		$props();
</script>

<div class="stat glass">
	<span class="stat-l">{label}</span>
	<b class="stat-v">{value}</b>
	{#if sub}<span class="stat-s">{sub}</span>{/if}
	{#if pct !== undefined}<Bar {pct} />{/if}
</div>
