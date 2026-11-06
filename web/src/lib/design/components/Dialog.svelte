<script lang="ts">
	import type { Snippet } from 'svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let {
		title,
		open = $bindable(false),
		sheet = false,
		children,
		footer
	}: {
		title: string;
		open?: boolean;
		sheet?: boolean;
		children: Snippet;
		footer?: Snippet;
	} = $props();

	let dialog = $state<HTMLDialogElement>();

	$effect(() => {
		if (open && !dialog?.open) dialog?.showModal();
		if (!open && dialog?.open) dialog.close();
	});
</script>

<dialog
	bind:this={dialog}
	data-lenis-prevent
	class={['glass', sheet ? 'sheet' : 'dlg']}
	aria-label={title}
	onclose={() => (open = false)}
>
	<header class="dlg-h">
		<h2>{title}</h2>
		<button
			type="button"
			class="icon-btn sm"
			aria-label={tr('Zatvori', 'Close')}
			onclick={() => (open = false)}>✕</button
		>
	</header>
	<div class="dlg-b">{@render children()}</div>
	{#if footer}<footer class="dlg-f">{@render footer()}</footer>{/if}
</dialog>
