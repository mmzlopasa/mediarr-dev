<script lang="ts">
	import type { Snippet } from 'svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import LangMenu from './LangMenu.svelte';
	import Logo from './Logo.svelte';
	import ThemeButton from './ThemeButton.svelte';

	let { children }: { children: Snippet } = $props();

	$effect.pre(() => {
		document.body.className = 'auth-page auth-split';
		return () => {
			document.body.className = '';
		};
	});
</script>

<main class="as" id="main">
	<section class="as-l">
		<div class="as-top">
			<Logo />
			<div class="auth-tools as-tools-m"><LangMenu /><ThemeButton /></div>
		</div>
		<div class="as-form">
			{@render children()}
			<p class="as-legal"><a href="https://mediarr.app">← mediarr.app</a></p>
		</div>
	</section>
	<aside class="as-r" aria-label="Mediarr">
		<div class="as-rtop">
			<LangMenu />
			<ThemeButton />
			<a class="as-cta" href="https://mediarr.app">mediarr.app</a>
		</div>
		<div class="as-edge" aria-hidden="true"></div>
		<div class="as-promo">
			<h2>
				{tr(
					'Sve vaše fotke i videi, na vašem poslužitelju.',
					'All your photos and videos, on your own server.'
				)}
			</h2>
			<p>{tr('Mediji · albumi · ljudi · karta', 'Media · albums · people · map')}</p>
		</div>
	</aside>
</main>
