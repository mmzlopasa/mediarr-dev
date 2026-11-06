<script lang="ts">
	import { magnet } from '#lib/motion/actions.ts';
	import type { Snippet } from 'svelte';
	import type { HTMLButtonAttributes } from 'svelte/elements';

	type Props = HTMLButtonAttributes & {
		variant?: 'default' | 'gold' | 'danger';
		small?: boolean;
		block?: boolean;
		href?: string;
		children: Snippet;
	};

	let {
		variant = 'default',
		small = false,
		block = false,
		href,
		type = 'button',
		children,
		...rest
	}: Props = $props();

	const cls = $derived(['btn', variant !== 'default' && variant, small && 'sm', block && 'block']);
</script>

{#if href}
	<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved href -->
	<a class={cls} {href} use:magnet={{ off: variant !== 'gold' || block }}>{@render children()}</a>
{:else}
	<button class={cls} {type} {...rest} use:magnet={{ off: variant !== 'gold' || block }}
		>{@render children()}</button
	>
{/if}
