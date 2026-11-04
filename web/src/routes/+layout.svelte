<script lang="ts">
	import '../app.css';
	import type { LayoutProps } from './$types';
	import { lang } from '#lib/i18n.svelte.ts';
	import { watchTheme } from '#lib/design/theme.ts';
	import Toasts from '#lib/design/components/Toasts.svelte';

	let { children }: LayoutProps = $props();

	$effect(() => watchTheme());
	// The loader from app.html covers the page until it can be used.
	$effect(() => {
		const boot = document.getElementById('boot');
		if (!boot) return;
		boot.style.opacity = '0';
		const timer = setTimeout(() => boot.remove(), 200);
		return () => clearTimeout(timer);
	});
	$effect(() => {
		document.documentElement.lang = lang();
	});

	const openMenus = () =>
		document.querySelectorAll<HTMLDetailsElement>('details.dd[open],details.langdd[open]');

	function onKey(event: KeyboardEvent) {
		if (event.key !== 'Escape') return;
		document.documentElement.classList.remove('side-open');
		openMenus().forEach((menu) => (menu.open = false));
	}

	function onClick(event: MouseEvent) {
		openMenus().forEach((menu) => {
			if (!menu.contains(event.target as Node)) menu.open = false;
		});
	}
</script>

<svelte:window onkeydown={onKey} onclick={onClick} />

<div class="sky" aria-hidden="true"></div>
{@render children()}
<Toasts />
