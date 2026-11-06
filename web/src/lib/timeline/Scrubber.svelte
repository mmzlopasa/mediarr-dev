<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';

	type Mark = { month: string; label: string; top: number; count: number };

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
	const indexAt = (at: number) => {
		const y = at * total;
		let found = 0;
		for (let i = 0; i < marks.length; i++) {
			if (marks[i].top <= y) found = i;
			else break;
		}
		return found;
	};
	const currentIndex = $derived(indexAt(fraction));
	const shown = $derived(marks[indexAt(shownFraction)]);

	// The edge of a film strip: one tick a month, as long as the month is full.
	const most = $derived(Math.max(1, ...marks.map((mark) => mark.count)));
	const ticks = $derived(
		marks.map((mark, index) => ({
			month: mark.month,
			fraction: total > 0 ? mark.top / total : 0,
			length: Math.sqrt(mark.count / most),
			// The first month of each year is marked a little longer, so a year label has its tick.
			first: index === 0 || marks[index - 1].month.slice(0, 4) !== mark.month.slice(0, 4)
		}))
	);
	// One label per year, kept apart on a short track.
	const years = $derived.by(() => {
		const seen: { year: string; fraction: number }[] = [];
		for (const mark of marks) {
			const year = mark.month.slice(0, 4);
			if (seen[seen.length - 1]?.year !== year) seen.push({ year, fraction: mark.top / total });
		}
		const out: typeof seen = [];
		for (const entry of seen) {
			if (!out.length || entry.fraction - out[out.length - 1].fraction > 0.05) out.push(entry);
		}
		return out;
	});
	const currentYear = $derived(marks[currentIndex]?.month.slice(0, 4));

	function fractionAt(event: PointerEvent) {
		const box = track?.getBoundingClientRect();
		if (!box || box.height === 0) return 0;
		return Math.min(1, Math.max(0, (event.clientY - box.top) / box.height));
	}

	// Jumps are immediate: this is used often, and motion would only make it slower.
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
	aria-valuetext={marks[currentIndex]?.label}
	onpointerdown={down}
	onpointermove={move}
	onpointerup={up}
	onpointercancel={up}
	onpointerleave={() => {
		if (!dragging) hoverY = null;
	}}
	onkeydown={key}
>
	{#each ticks as tick, index (tick.month)}
		<i
			class="scrub-tick"
			class:first={tick.first}
			class:now={index === currentIndex}
			style="top:{tick.fraction * 100}%;--len:{tick.length}"
		></i>
	{/each}
	{#each years as entry (entry.year)}
		<span
			class="scrub-year"
			class:now={entry.year === currentYear}
			style="top:{entry.fraction * 100}%">{entry.year}</span
		>
	{/each}
	{#if (hoverY !== null || dragging) && shown}
		<b class="scrub-label" style="top:{shownFraction * 100}%">{shown.label}</b>
	{/if}
</div>
