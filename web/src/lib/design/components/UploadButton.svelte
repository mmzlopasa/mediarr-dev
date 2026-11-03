<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';
	import { addUploads, setPreparingUpload } from '#lib/uploads.svelte.ts';
	import Icon from './Icon.svelte';

	// Listed so that iOS sends HEIC originals instead of converting them to JPEG.
	const ACCEPT =
		'image/*,video/*,image/heic,image/heif,.heic,.heif,.dng,.cr2,.cr3,.nef,.arw,.raf,.rw2,.orf,.pef';

	// Each selection gets a new input, and old ones stay on the page. Clearing an input can make
	// iOS delete the temporary copies of the photos it picked, while they are still uploading.
	let inputs = $state([0]);
	const active = $derived(inputs[inputs.length - 1]);

	function chosen(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		if (input.files?.length) addUploads(input.files);
		else setPreparingUpload(false);
		inputs = [...inputs, active + 1];
	}

	function opening() {
		setPreparingUpload(true);
	}

	function key(event: KeyboardEvent) {
		if (event.key !== 'Enter' && event.key !== ' ') return;
		event.preventDefault();
		document.getElementById(`upload-input-${active}`)?.click();
	}
</script>

<!-- A real label, because iOS is most reliable when a tap reaches the input directly. -->
<!-- svelte-ignore a11y_no_noninteractive_element_to_interactive_role -->
<label
	class="btn gold sm"
	for="upload-input-{active}"
	role="button"
	tabindex="0"
	onclick={opening}
	onkeydown={key}
>
	<Icon name="upload" size={14} />
	{tr('Upload', 'Upload')}
</label>
{#each inputs as id (id)}
	<input
		id="upload-input-{id}"
		class="sr"
		type="file"
		multiple
		accept={ACCEPT}
		tabindex="-1"
		aria-label={tr('Odaberi datoteke', 'Choose files')}
		onchange={chosen}
		oncancel={() => setPreparingUpload(false)}
	/>
{/each}
