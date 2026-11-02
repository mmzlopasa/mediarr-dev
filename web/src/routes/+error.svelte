<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { tr } from '#lib/i18n.svelte.ts';
</script>

<svelte:head><title>{page.status} — Mediarr</title></svelte:head>

<main class="auth-wrap">
	<div class="auth-card glass">
		<h1 class="auth-h">{page.status}</h1>
		<p class="auth-p">{tr('Ova stranica ne postoji.', 'This page does not exist.')}</p>
		<a class="btn gold" href={resolve('/(app)')}>{tr('Natrag na fotke', 'Back to photos')}</a>
	</div>
</main>
