<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type Notification } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import type { IconName } from '#lib/design/icons.ts';
	import { since } from './agent.ts';

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

	// The same message again and again (a backup failing every night) is one row with a count.
	type Group = { first: Notification; ids: string[]; unread: boolean };
	const groups = $derived.by(() => {
		const out: Group[] = [];
		const byText: Record<string, Group> = {};
		for (const item of items ?? []) {
			const key = `${item.kind}\u0000${item.subject}\u0000${item.ref ?? ''}`;
			const group = byText[key];
			if (group) {
				group.ids.push(item.id);
				group.unread ||= !item.read;
			} else {
				byText[key] = { first: item, ids: [item.id], unread: !item.read };
				out.push(byText[key]);
			}
		}
		return out;
	});

	async function remove(ids: string[]) {
		try {
			await Promise.all(ids.map((id) => api.deleteNotification(id)));
			items = items?.filter((item) => !ids.includes(item.id));
		} catch {
			failed = true;
		}
	}

	const failure = (item: Notification) =>
		item.kind === 'import_failed' || item.kind === 'backup_failed';

	function icon(item: Notification): IconName {
		switch (item.kind) {
			case 'album_shared':
				return 'album';
			case 'import_done':
				return 'download';
			default:
				return 'warn';
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
				return tr('Sigurnosna kopija nije uspjela', 'A backup failed');
		}
	}

	// What went wrong, when the message carries it.
	function detail(item: Notification): string {
		return item.kind === 'backup_failed' ? item.subject : '';
	}
</script>

<svelte:window
	onpointerdown={(event) => {
		if (open && !(event.target as HTMLElement).closest('.notify')) open = false;
	}}
	onkeydown={(event) => {
		if (event.key === 'Escape') open = false;
	}}
/>

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
		<div class="notify-panel lb-pop" data-lenis-prevent>
			<header class="notify-h">
				<b>{tr('Obavijesti', 'Notifications')}</b>
				{#if items?.length}
					<button
						type="button"
						class="notify-clear"
						onclick={() => remove((items ?? []).map((item) => item.id))}
						>{tr('Očisti sve', 'Clear all')}</button
					>
				{/if}
			</header>
			{#if failed}
				<p class="notify-empty">{tr('Podaci se ne mogu učitati.', 'This could not be loaded.')}</p>
			{:else if !items}
				<div class="notify-list"><Skeleton height="56px" /><Skeleton height="56px" /></div>
			{:else if groups.length === 0}
				<p class="notify-empty">{tr('Nema obavijesti.', 'No notifications.')}</p>
			{:else}
				<ul class="notify-list">
					{#each groups as group (group.first.id)}
						{@const item = group.first}
						<li class="notify-row" class:unread={group.unread} class:bad={failure(item)}>
							<span class="notify-ic"><Icon name={icon(item)} size={16} /></span>
							<div class="notify-t">
								{#if item.kind === 'album_shared' && item.ref}
									<a
										href={resolve('/(app)/albums/[id]', { id: item.ref })}
										onclick={() => (open = false)}>{sentence(item)}</a
									>
								{:else}
									<b>{sentence(item)}</b>
								{/if}
								{#if detail(item)}
									<button
										type="button"
										class="notify-detail"
										title={detail(item)}
										onclick={(event) => event.currentTarget.classList.toggle('open')}
										>{detail(item)}</button
									>
								{/if}
								<small>
									<time datetime={item.createdAt} title={new Date(item.createdAt).toLocaleString()}
										>{since(new Date(item.createdAt))}</time
									>
									{#if group.ids.length > 1}
										· {tr(`${group.ids.length} puta`, `${group.ids.length} times`)}{/if}
								</small>
							</div>
							<button
								type="button"
								class="icon-btn sm notify-x"
								aria-label={tr('Ukloni', 'Remove')}
								onclick={() => remove(group.ids)}
							>
								<Icon name="x" size={14} />
							</button>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	{/if}
</div>
