<script lang="ts">
	// A meter warns as it fills (disk space); progress (work done) never does.
	let {
		pct,
		label = `${pct} %`,
		progress = false
	}: { pct: number; label?: string; progress?: boolean } = $props();
</script>

<div
	class="bar"
	role="progressbar"
	aria-label={label}
	aria-valuenow={pct}
	aria-valuemin="0"
	aria-valuemax="100"
>
	<i class={progress ? '' : pct > 90 ? 'bad' : pct > 75 ? 'warn' : ''} style="width:{pct}%"></i>
</div>
