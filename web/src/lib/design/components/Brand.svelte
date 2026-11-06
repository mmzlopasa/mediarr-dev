<script lang="ts">
	// Mediarr's mark and name: six photos fanned out, and a gold sun as the dot of the i.
	// Decorative: whatever contains it carries the accessible name.
	const colors = ['#ffc83d', '#ff9f43', '#ff5e57', '#ff7eb6', '#3a55c9', '#2ec4a6'];
	// Under the name runs a film edge, one tick per month; the gold one sits under the i.
	const ticks = [10, 16, 7, 22, 12, 18, 9, 14, 20, 8, 15, 11, 17, 6, 13, 19, 9];
	const gold = 10;
	let { word = true }: { word?: boolean } = $props();
</script>

<span class="brand" aria-hidden="true">
	<svg class="brand-mark" viewBox="5 5 54 54">
		{#each colors as color, i (color)}
			<rect
				x="27"
				y="7"
				width="13"
				height="24"
				rx="4"
				fill={color}
				opacity=".92"
				transform="rotate({i * 60} 32 32)"
			/>
		{/each}
	</svg>
	{#if word}
		<span class="brand-name">
			<span class="brand-word">med<span class="brand-i">ı<i></i></span>arr</span>
			<svg class="brand-edge" viewBox="0 0 326 28" preserveAspectRatio="none">
				{#each ticks as length, i (i)}
					<rect
						x={i * 20}
						y={28 - length * 1.196}
						width="6"
						height={length * 1.196}
						rx="3"
						class:gold={i === gold}
					/>
				{/each}
			</svg>
		</span>
	{/if}
</span>
