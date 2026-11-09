<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { t } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import Icon from './Icon.svelte';

	let { items }: { items: NavItem[] } = $props();

	let dialog = $state<HTMLDialogElement>();
	let query = $state('');
	let selected = $state(0);

	const results = $derived(
		items.filter((item) => t(item.label).toLowerCase().includes(query.trim().toLowerCase()))
	);

	export function open() {
		query = '';
		selected = 0;
		dialog?.showModal();
	}

	function run(item: NavItem) {
		dialog?.close();
		// eslint-disable-next-line @typescript-eslint/no-explicit-any -- paths come from the static nav list
		goto(resolve(item.path as any));
	}

	function onGlobalKey(event: KeyboardEvent) {
		if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
			event.preventDefault();
			if (dialog?.open) dialog.close();
			else open();
		}
	}

	function onInputKey(event: KeyboardEvent) {
		if (event.key === 'ArrowDown') {
			event.preventDefault();
			selected = Math.min(selected + 1, results.length - 1);
		} else if (event.key === 'ArrowUp') {
			event.preventDefault();
			selected = Math.max(selected - 1, 0);
		} else if (event.key === 'Enter' && results[selected]) {
			event.preventDefault();
			run(results[selected]);
		}
	}
</script>

<svelte:window onkeydown={onGlobalKey} />

<dialog
	bind:this={dialog}
	data-lenis-prevent
	class="cmd glass"
	aria-label={t('commandPalette.commandPalette')}
>
	<div class="cmd-in">
		<input
			class="in"
			type="search"
			aria-label={t('commandPalette.searchCommands')}
			placeholder={t('commandPalette.goTo')}
			bind:value={query}
			oninput={() => (selected = 0)}
			onkeydown={onInputKey}
		/>
	</div>
	<ul class="cmd-l">
		{#each results as item, index (item.path)}
			<li>
				<button
					type="button"
					class="nav-i cmd-i"
					class:on={index === selected}
					onclick={() => run(item)}
				>
					<span class="ic"><Icon name={item.icon} /></span>
					<span>{t(item.label)}</span>
				</button>
			</li>
		{:else}
			<li class="empty"><p>{t('commandPalette.noResults')}</p></li>
		{/each}
	</ul>
</dialog>
