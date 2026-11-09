<script lang="ts">
	import { onMount } from 'svelte';
	import { t } from '#lib/i18n.svelte.ts';

	// The parts of a long settings page, to jump between them; the one in view is marked.
	let { items }: { items: { id: string; label: string }[] } = $props();

	let active = $state('');

	onMount(() => {
		const seen: Record<string, boolean> = {};
		// At the very bottom the last parts can never reach the top, so the last one counts.
		const atBottom = () =>
			window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 4;
		const pick = () => {
			const last = items[items.length - 1];
			if (atBottom() && last && document.getElementById(last.id)) active = last.id;
			else active = items.find((item) => seen[item.id])?.id ?? active;
		};
		window.addEventListener('scroll', pick, { passive: true });
		const observer = new IntersectionObserver(
			(entries) => {
				for (const entry of entries) seen[entry.target.id] = entry.isIntersecting;
				pick();
			},
			{ rootMargin: '-80px 0px -55% 0px' }
		);
		const watch = () => {
			observer.disconnect();
			for (const item of items) {
				const target = document.getElementById(item.id);
				if (target) observer.observe(target);
			}
		};
		watch();
		// Sections appear as their data loads.
		const later = setTimeout(watch, 1200);
		return () => {
			window.removeEventListener('scroll', pick);
			clearTimeout(later);
			observer.disconnect();
		};
	});
</script>

<nav class="set-nav" aria-label={t('sectionNav.sections')}>
	{#each items as item (item.id)}
		<a
			href="#{item.id}"
			class:on={active === item.id}
			aria-current={active === item.id ? 'location' : undefined}>{item.label}</a
		>
	{/each}
</nav>
