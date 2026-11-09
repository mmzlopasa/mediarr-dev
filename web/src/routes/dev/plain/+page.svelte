<script lang="ts">
	import { t } from '#lib/i18n.svelte.ts';

	$effect.pre(() => {
		document.body.classList.add('plain-view');
		return () => document.body.classList.remove('plain-view');
	});
</script>

<main class="plain-stage" id="main">
	<h1>{t('dev.plain.singlePhotoView')}</h1>
</main>
