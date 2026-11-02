<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';
	import { addUploads } from '#lib/uploads.svelte.ts';
	import Button from './Button.svelte';
	import Icon from './Icon.svelte';

	let input = $state<HTMLInputElement>();

	function chosen() {
		if (!input?.files) return;
		addUploads(input.files);
		input.value = '';
	}
</script>

<Button variant="gold" small onclick={() => input?.click()}>
	<Icon name="upload" size={14} />
	{tr('Upload', 'Upload')}
</Button>
<input
	bind:this={input}
	class="sr"
	type="file"
	multiple
	tabindex="-1"
	aria-label={tr('Odaberi datoteke', 'Choose files')}
	onchange={chosen}
/>
