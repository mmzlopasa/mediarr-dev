<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { t } from '#lib/i18n.svelte.ts';
</script>

<svelte:head><title>{page.status} — Mediarr</title></svelte:head>

<main class="auth-wrap">
	<div class="auth-card glass">
		<h1 class="auth-h">{page.status}</h1>
		<p class="auth-p">{t('home.thisPageDoesNotExist')}</p>
		<a class="btn gold" href={resolve('/(app)')}>{t('home.backToPhotos')}</a>
	</div>
</main>
