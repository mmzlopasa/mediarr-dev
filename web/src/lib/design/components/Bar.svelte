<script lang="ts">
	let { pct, label = `${pct} %` }: { pct: number; label?: string } = $props();
</script>

<div
	class="bar"
	role="progressbar"
	aria-label={label}
	aria-valuenow={pct}
	aria-valuemin="0"
	aria-valuemax="100"
>
	<i class={pct > 90 ? 'bad' : pct > 75 ? 'warn' : ''} style="width:{pct}%"></i>
</div>
