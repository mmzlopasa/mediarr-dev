<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';

	$effect.pre(() => {
		document.body.classList.add('plain-view');
		return () => document.body.classList.remove('plain-view');
	});
</script>

<main class="plain-stage" id="main">
	<h1>{tr('Prikaz jedne fotke', 'Single photo view')}</h1>
</main>
