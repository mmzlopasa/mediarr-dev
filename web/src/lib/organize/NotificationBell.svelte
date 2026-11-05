<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type Notification } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	const REFRESH = 60_000;

	let items = $state<Notification[]>();
	let unread = $state(0);
	let open = $state(false);
	let failed = $state(false);

	async function load() {
		try {
			const list = await api.notifications();
			items = list.items;
			unread = list.unread;
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(() => {
		void load();
		const timer = setInterval(() => void load(), REFRESH);
		return () => clearInterval(timer);
	});

	async function toggle() {
		open = !open;
		if (!open) return;
		await load();
		if (unread > 0) {
			try {
				await api.readNotifications();
				unread = 0;
			} catch {
				// They stay unread and are counted again on the next look.
			}
		}
	}

	async function remove(id: string) {
		try {
			await api.deleteNotification(id);
			items = items?.filter((item) => item.id !== id);
		} catch {
			failed = true;
		}
	}

	function sentence(item: Notification): string {
		switch (item.kind) {
			case 'album_shared':
				return tr(
					`S vama je podijeljen album „${item.subject}”`,
					`“${item.subject}” was shared with you`
				);
			case 'import_done':
				return tr(
					`Uvoz iz izvora ${item.subject} je završen`,
					`The import from ${item.subject} finished`
				);
			case 'import_failed':
				return tr(
					`Uvoz iz izvora ${item.subject} nije uspio`,
					`The import from ${item.subject} failed`
				);
			case 'backup_failed':
				return tr(
					`Sigurnosna kopija nije uspjela: ${item.subject}`,
					`A backup failed: ${item.subject}`
				);
		}
	}
</script>

<div class="notify">
	<button
		type="button"
		class="icon-btn"
		aria-expanded={open}
		aria-label={tr('Obavijesti', 'Notifications')}
		title={tr('Obavijesti', 'Notifications')}
		onclick={toggle}
	>
		<Icon name="bell" />
	</button>
	{#if unread > 0}<span class="notify-count">{unread > 99 ? '99+' : unread}</span>{/if}
	{#if open}
		<div class="notify-panel">
			{#if failed}
				<p class="alb-meta">{tr('Podaci se ne mogu učitati.', 'This could not be loaded.')}</p>
			{:else if !items}
				<Skeleton height="60px" />
			{:else if items.length === 0}
				<p class="alb-meta">{tr('Nema obavijesti.', 'No notifications.')}</p>
			{:else}
				{#each items as item (item.id)}
					<div class="notify-row" class:unread={!item.read}>
						{#if item.kind === 'album_shared' && item.ref}
							<a
								href={resolve('/(app)/albums/[id]', { id: item.ref })}
								onclick={() => (open = false)}
							>
								{sentence(item)}<small>{new Date(item.createdAt).toLocaleString()}</small>
							</a>
						{:else}
							<span>{sentence(item)}<small>{new Date(item.createdAt).toLocaleString()}</small></span
							>
						{/if}
						<button
							type="button"
							class="icon-btn sm"
							aria-label={tr('Ukloni', 'Remove')}
							onclick={() => remove(item.id)}
						>
							<Icon name="x" size={14} />
						</button>
					</div>
				{/each}
			{/if}
		</div>
	{/if}
</div>
