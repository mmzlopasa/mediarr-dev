<script lang="ts">
	import type { Snippet } from 'svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import LangMenu from './LangMenu.svelte';
	import Logo from './Logo.svelte';
	import ThemeButton from './ThemeButton.svelte';
	import DotGrid from '#lib/motion/DotGrid.svelte';
	import { revealTitle } from '#lib/motion/actions.ts';
	import { motionKit, reduced } from '#lib/motion/motion.ts';

	let { children }: { children: Snippet } = $props();

	// Fetch the motion code at once, so the first title can still rise.
	if (typeof window !== 'undefined' && !reduced()) void motionKit();

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
		<DotGrid />
		<div class="as-rtop">
			<LangMenu />
			<ThemeButton />
			<a class="as-cta" href="https://mediarr.app">mediarr.app</a>
		</div>
		<div class="as-edge" aria-hidden="true"></div>
		<div class="as-promo">
			<h2 use:revealTitle>
				{t('authLayout.allYourPhotosAndVideos')}
			</h2>
			<p>{t('authLayout.mediaAlbumsPeopleMap')}</p>
		</div>
	</aside>
</main>
