<script lang="ts">
	// A person: their picture when they have one, otherwise their initials. A picture that does not
	// load falls back to the initials, never to a broken image.
	let { initials, src }: { initials: string; src?: string } = $props();
	let failed = $state(false);
	$effect(() => {
		void src;
		failed = false;
	});
	const pic = $derived(Boolean(src) && !failed);
</script>

<span class="av" class:pic aria-hidden="true"
	>{#if pic}<img
			{src}
			alt=""
			loading="lazy"
			decoding="async"
			onerror={() => (failed = true)}
		/>{:else}{initials}{/if}</span
>
