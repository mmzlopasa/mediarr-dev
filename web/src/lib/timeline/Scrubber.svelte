<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';

	type Mark = { month: string; label: string; top: number };

	let {
		marks,
		total,
		position,
		onSeek
	}: { marks: Mark[]; total: number; position: number; onSeek: (y: number) => void } = $props();

	let track = $state<HTMLDivElement>();
	let dragging = $state(false);
	let hoverY = $state<number | null>(null);

	const fraction = $derived(total > 0 ? Math.min(1, Math.max(0, position / total)) : 0);
	const shownFraction = $derived(hoverY ?? fraction);
	const current = $derived.by(() => {
		const y = shownFraction * total;
		let found = marks[0];
		for (const mark of marks) {
			if (mark.top <= y) found = mark;
			else break;
		}
		return found;
	});
	// One label per year, for orientation on the track.
	const years = $derived.by(() => {
		const seen: { year: string; fraction: number }[] = [];
		for (const mark of marks) {
			const year = mark.month.slice(0, 4);
			if (seen[seen.length - 1]?.year !== year) seen.push({ year, fraction: mark.top / total });
		}
		// Keep labels from touching on a short track.
		const out: typeof seen = [];
		for (const entry of seen) {
			if (!out.length || entry.fraction - out[out.length - 1].fraction > 0.05) out.push(entry);
		}
		return out;
	});

	function fractionAt(event: PointerEvent) {
		const box = track?.getBoundingClientRect();
		if (!box || box.height === 0) return 0;
		return Math.min(1, Math.max(0, (event.clientY - box.top) / box.height));
	}

	function down(event: PointerEvent) {
		event.preventDefault();
		dragging = true;
		track?.setPointerCapture(event.pointerId);
		onSeek(fractionAt(event) * total);
	}

	function move(event: PointerEvent) {
		const at = fractionAt(event);
		if (dragging) onSeek(at * total);
		hoverY = at;
	}

	function up() {
		dragging = false;
		hoverY = null;
	}

	function key(event: KeyboardEvent) {
		const step = event.key === 'PageDown' || event.key === 'PageUp' ? 0.1 : 0.02;
		if (event.key === 'ArrowDown' || event.key === 'PageDown') onSeek(position + step * total);
		else if (event.key === 'ArrowUp' || event.key === 'PageUp') onSeek(position - step * total);
		else return;
		event.preventDefault();
	}
</script>

<div
	bind:this={track}
	class="scrub"
	class:on={dragging}
	role="slider"
	tabindex="0"
	aria-label={tr('Vremenska crta', 'Timeline')}
	aria-valuemin="0"
	aria-valuemax="100"
	aria-valuenow={Math.round(fraction * 100)}
	aria-valuetext={current?.label}
	onpointerdown={down}
	onpointermove={move}
	onpointerup={up}
	onpointercancel={up}
	onpointerleave={() => {
		if (!dragging) hoverY = null;
	}}
	onkeydown={key}
>
	{#each years as entry (entry.year)}
		<span class="scrub-year" style="top:{entry.fraction * 100}%">{entry.year}</span>
	{/each}
	<i class="scrub-thumb" style="top:{fraction * 100}%"></i>
	{#if (hoverY !== null || dragging) && current}
		<b class="scrub-label" style="top:{shownFraction * 100}%">{current.label}</b>
	{/if}
</div>
