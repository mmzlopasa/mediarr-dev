<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { t } from '#lib/i18n.svelte.ts';
	import { errorKind } from '#lib/errors.ts';

	// A missing page, a server that is down or busy, and a lost connection each say what they are.
	const kind = $derived(
		page.status === 404
			? 'notFound'
			: (page.error?.kind ??
					errorKind(page.status, typeof navigator !== 'undefined' ? navigator.onLine : true))
	);
	const text = $derived(
		kind === 'notFound'
			? t('home.thisPageDoesNotExist')
			: kind === 'unavailable'
				? t('common.serverUnavailable')
				: kind === 'offline'
					? t('common.serverUnreachable')
					: t('common.serverError')
	);
</script>

<svelte:head><title>{page.status} — Mediarr</title></svelte:head>

<main class="auth-wrap">
	<div class="auth-card glass">
		<h1 class="auth-h">{page.status}</h1>
		<p class="auth-p" data-error-kind={kind}>{text}</p>
		{#if kind !== 'notFound'}
			<div class="auth-tools">
				<button type="button" class="btn gold" onclick={() => location.reload()}
					>{t('common.tryAgain')}</button
				>
				<a class="btn" href={resolve('/(app)')}>{t('home.backToPhotos')}</a>
			</div>
		{:else}
			<a class="btn gold" href={resolve('/(app)')}>{t('home.backToPhotos')}</a>
		{/if}
	</div>
</main>
