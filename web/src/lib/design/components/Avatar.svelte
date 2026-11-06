<script lang="ts">
	// A person: their picture when they have one, otherwise their initials.
	let { initials, src }: { initials: string; src?: string } = $props();
</script>

<span class="av" class:pic={Boolean(src)} aria-hidden="true"
	>{#if src}<img {src} alt="" loading="lazy" decoding="async" />{:else}{initials}{/if}</span
>
