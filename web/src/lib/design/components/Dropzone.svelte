<script lang="ts">
	import { t } from '#lib/i18n.svelte.ts';
	import { addUploads } from '#lib/uploads.svelte.ts';
	import Icon from './Icon.svelte';

	let depth = $state(0);

	const hasFiles = (event: DragEvent) => event.dataTransfer?.types.includes('Files') ?? false;

	function enter(event: DragEvent) {
		if (hasFiles(event)) depth += 1;
	}

	function leave(event: DragEvent) {
		if (hasFiles(event)) depth = Math.max(0, depth - 1);
	}

	function over(event: DragEvent) {
		if (hasFiles(event)) event.preventDefault();
	}

	function drop(event: DragEvent) {
		if (!hasFiles(event)) return;
		event.preventDefault();
		depth = 0;
		addUploads(event.dataTransfer?.files ?? []);
	}
</script>

<svelte:window ondragenter={enter} ondragleave={leave} ondragover={over} ondrop={drop} />

{#if depth > 0}
	<div class="drop" role="status">
		<span class="btn-row"><Icon name="upload" /> {t('dropzone.dropToUpload')}</span>
	</div>
{/if}
