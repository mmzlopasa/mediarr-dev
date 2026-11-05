<script lang="ts">
	import { onMount } from 'svelte';
	import type { Snippet } from 'svelte';
	import { afterNavigate, goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, initialsOf, type User } from '#lib/api.ts';
	import NotificationBell from '#lib/organize/NotificationBell.svelte';
	import type { IconName } from '../icons.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import Avatar from './Avatar.svelte';
	import CommandPalette from './CommandPalette.svelte';
	import Icon from './Icon.svelte';
	import LangMenu from './LangMenu.svelte';
	import Logo from './Logo.svelte';
	import ThemeButton from './ThemeButton.svelte';
	import UploadButton from './UploadButton.svelte';

	let {
		nav,
		tag,
		user,
		roleLabel,
		footLinks,
		sideExtra,
		children
	}: {
		nav: NavItem[];
		tag?: string;
		user: User;
		roleLabel: string;
		footLinks: { href: string; icon: IconName; label: string }[];
		sideExtra?: Snippet;
		children: Snippet;
	} = $props();

	// The dock holds the places people go every day; the rest are one tap away under More.
	const DOCK = ['/', '/people', '/map', '/albums'];

	const admin = $derived(Boolean(tag));
	const docked = $derived(
		admin
			? []
			: DOCK.map((path) => nav.find((item) => item.path === path)).filter(
					(item): item is NavItem => item !== undefined
				)
	);
	const more = $derived(admin ? nav : nav.filter((item) => !DOCK.includes(item.path)));

	let moreOpen = $state(false);
	let meOpen = $state(false);
	let maintained = $state(false);
	let palette = $state<CommandPalette>();

	function current(path: string) {
		const here = page.url.pathname;
		if (path === '/' || path === '/admin') return here === path;
		return here === path || here.startsWith(`${path}/`);
	}

	function closeAll() {
		moreOpen = false;
		meOpen = false;
	}

	afterNavigate(closeAll);

	onMount(() => {
		const onMaintenance = () => (maintained = true);
		window.addEventListener('mediarr:maintenance', onMaintenance);
		return () => window.removeEventListener('mediarr:maintenance', onMaintenance);
	});

	$effect.pre(() => {
		document.body.className = 'app';
		return () => {
			document.body.className = '';
		};
	});

	function onKey(event: KeyboardEvent) {
		if (event.key === 'Escape') closeAll();
	}

	function onPointer(event: PointerEvent) {
		const target = event.target as HTMLElement;
		if (!target.closest('.lb-more, .lb-more-b')) moreOpen = false;
		if (!target.closest('.lb-me')) meOpen = false;
	}

	async function signOut(event: SubmitEvent) {
		event.preventDefault();
		await api.logout();
		await goto(resolve('/login'), { invalidateAll: true });
	}

	function search(event: SubmitEvent) {
		event.preventDefault();
		const query = new FormData(event.target as HTMLFormElement).get('q');
		goto(
			// eslint-disable-next-line svelte/no-navigation-without-resolve -- the path is resolved here
			`${resolve('/(app)/[section]', { section: 'search' })}?q=${encodeURIComponent(String(query ?? ''))}`
		);
	}
</script>

<svelte:window onkeydown={onKey} onpointerdown={onPointer} />

<a class="skip" href="#main">{tr('Preskoči na sadržaj', 'Skip to content')}</a>
<div class="lb-shell" class:lb-admin={admin}>
	<header class="lb-top">
		<Logo {tag} />
		<div class="lb-top-r">
			<NotificationBell />
			<div class="lb-me">
				<button
					type="button"
					class="lb-me-b"
					aria-expanded={meOpen}
					aria-label={tr('Račun', 'Account')}
					onclick={() => (meOpen = !meOpen)}
				>
					<Avatar initials={initialsOf(user.name)} />
				</button>
				{#if meOpen}
					<div class="lb-pop lb-me-m">
						<div class="lb-me-h"><b>{user.name}</b><small>{roleLabel}</small></div>
						{#each footLinks as link (link.href)}
							<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved href -->
							<a class="lb-pop-i" href={link.href}><Icon name={link.icon} />{link.label}</a>
						{/each}
						<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
						<a class="lb-pop-i" href="/tv"><Icon name="tv" />{tr('TV način', 'TV mode')}</a>
						<div class="lb-me-tools"><LangMenu /><ThemeButton /></div>
						<form onsubmit={signOut}>
							<button class="lb-pop-i" type="submit"
								><Icon name="out" />{tr('Odjava', 'Sign out')}</button
							>
						</form>
					</div>
				{/if}
			</div>
		</div>
	</header>

	{#if admin}
		<nav class="lb-side" aria-label={tr('Navigacija', 'Navigation')}>
			{#each nav as item (item.path)}
				<!-- eslint-disable svelte/no-navigation-without-resolve -- paths come from the static nav list -->
				<a
					href={item.path}
					class="lb-side-i"
					class:on={current(item.path)}
					aria-current={current(item.path) ? 'page' : undefined}
				>
					<Icon name={item.icon} /><span>{tr(item.hr, item.en)}</span>
				</a>
				<!-- eslint-enable svelte/no-navigation-without-resolve -->
			{/each}
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
			<a href="/" class="lb-side-i lb-side-back"
				><Icon name="photo" /><span>{tr('Natrag na medije', 'Back to media')}</span></a
			>
		</nav>
	{:else}
		<nav class="lb-dock" aria-label={tr('Navigacija', 'Navigation')}>
			{#each docked as item (item.path)}
				<!-- eslint-disable svelte/no-navigation-without-resolve -- paths come from the static nav list -->
				<a
					href={item.path}
					class="lb-dock-i"
					class:on={current(item.path)}
					aria-current={current(item.path) ? 'page' : undefined}
				>
					<Icon name={item.icon} /><span>{tr(item.hr, item.en)}</span>
				</a>
				<!-- eslint-enable svelte/no-navigation-without-resolve -->
			{/each}
			{#if more.length}
				<button
					type="button"
					class="lb-dock-i lb-more-b"
					class:on={more.some((item) => current(item.path))}
					aria-expanded={moreOpen}
					onclick={() => (moreOpen = !moreOpen)}
				>
					<Icon name="grid" /><span>{tr('Više', 'More')}</span>
				</button>
			{/if}
			<form class="lb-ask" role="search" onsubmit={search}>
				<label class="sr" for="gs-q">{tr('Traži', 'Search')}</label>
				<Icon name="search" size={18} />
				<input
					id="gs-q"
					name="q"
					type="search"
					placeholder={tr('Pitaj svoje fotke', 'Ask your photos')}
					autocomplete="off"
				/>
				<button type="button" class="lb-kbd" onclick={() => palette?.open()}>⌘K</button>
			</form>
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
			<a href="/search" class="lb-dock-i lb-ask-m" aria-label={tr('Traži', 'Search')}
				><Icon name="search" /></a
			>
			<span class="lb-add"><UploadButton compact /></span>
			{#if moreOpen}
				<div class="lb-pop lb-more">
					<div class="lb-more-g">
						{#each more as item (item.path)}
							<!-- eslint-disable svelte/no-navigation-without-resolve -- paths come from the static nav list -->
							<a
								href={item.path}
								class="lb-more-i"
								class:on={current(item.path)}
								aria-current={current(item.path) ? 'page' : undefined}
							>
								<Icon name={item.icon} /><span>{tr(item.hr, item.en)}</span>
							</a>
							<!-- eslint-enable svelte/no-navigation-without-resolve -->
						{/each}
					</div>
					{@render sideExtra?.()}
				</div>
			{/if}
		</nav>
	{/if}

	<main id="main" class="main" tabindex="-1">
		{#if maintained}
			<p class="maintenance" role="status">
				{tr(
					'Poslužitelj je na održavanju. Pokušajte ponovo kasnije.',
					'This server is being maintained. Try again later.'
				)}
			</p>
		{/if}
		{@render children()}
	</main>
</div>
<CommandPalette bind:this={palette} items={nav} />
