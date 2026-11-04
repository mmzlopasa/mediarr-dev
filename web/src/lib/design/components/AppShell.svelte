<script lang="ts">
	import { onMount } from 'svelte';
	import type { Snippet } from 'svelte';
	import { afterNavigate, goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, initialsOf, type User } from '#lib/api.ts';
	import type { IconName } from '../icons.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import Avatar from './Avatar.svelte';
	import CommandPalette from './CommandPalette.svelte';
	import Icon from './Icon.svelte';
	import LangMenu from './LangMenu.svelte';
	import Logo from './Logo.svelte';
	import ThemeButton from './ThemeButton.svelte';

	let {
		nav,
		tag,
		user,
		roleLabel,
		footLabel,
		footLinks,
		sideExtra,
		navChildren = {},
		children
	}: {
		nav: NavItem[];
		tag?: string;
		user: User;
		roleLabel: string;
		footLabel: string;
		footLinks: { href: string; icon: IconName; label: string }[];
		sideExtra?: Snippet;
		navChildren?: Record<string, () => Promise<{ href: string; label: string }[]>>;
		children: Snippet;
	} = $props();

	const OPEN_KEY = 'mediarr_nav_open';
	let openPaths = $state<string[]>([]);
	let children_ = $state<Record<string, { href: string; label: string }[]>>({});

	async function loadChildren(path: string) {
		try {
			children_[path] = (await navChildren[path]?.()) ?? [];
		} catch {
			children_[path] = [];
		}
	}

	function toggleChildren(path: string) {
		if (openPaths.includes(path)) {
			openPaths = openPaths.filter((other) => other !== path);
		} else {
			openPaths = [...openPaths, path];
			loadChildren(path);
		}
		try {
			localStorage.setItem(OPEN_KEY, JSON.stringify(openPaths));
		} catch {
			// Storage can be blocked; the menu still works on this page.
		}
	}

	onMount(() => {
		try {
			const saved: unknown = JSON.parse(localStorage.getItem(OPEN_KEY) ?? '[]');
			if (Array.isArray(saved)) {
				openPaths = saved.filter((path) => path in navChildren);
				openPaths.forEach(loadChildren);
			}
		} catch {
			// Nothing was saved in a form that can be read.
		}
	});

	const closeSide = () => document.documentElement.classList.remove('side-open');
	const openSide = () => document.documentElement.classList.add('side-open');

	afterNavigate(closeSide);

	$effect.pre(() => {
		document.body.className = 'app';
		return () => {
			document.body.className = '';
			closeSide();
		};
	});

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

<a class="skip" href="#main">{tr('Preskoči na sadržaj', 'Skip to content')}</a>
<div class="layout">
	<aside class="side glass" id="side" aria-label={tr('Navigacija', 'Navigation')}>
		<div class="side-top">
			<Logo {tag} />
			<button
				class="icon-btn side-x"
				type="button"
				aria-label={tr('Zatvori izbornik', 'Close menu')}
				onclick={closeSide}>✕</button
			>
		</div>
		<nav class="nav">
			{#each nav as item (item.path)}
				{@const on = page.url.pathname === item.path}
				<div class="nav-row">
					<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- paths come from the static nav list -->
					<a href={item.path} class="nav-i" class:on aria-current={on ? 'page' : undefined}>
						<span class="ic"><Icon name={item.icon} /></span>
						<span>{tr(item.hr, item.en)}</span>
					</a>
					{#if navChildren[item.path]}
						<button
							type="button"
							class="nav-more"
							class:open={openPaths.includes(item.path)}
							aria-expanded={openPaths.includes(item.path)}
							aria-label={tr(`Proširi: ${item.hr}`, `Expand ${item.en}`)}
							onclick={() => toggleChildren(item.path)}
						>
							<svg
								width="14"
								height="14"
								viewBox="0 0 24 24"
								fill="none"
								stroke="currentColor"
								stroke-width="2"><path d="m6 9 6 6 6-6" /></svg
							>
						</button>
					{/if}
				</div>
				{#if openPaths.includes(item.path)}
					<div class="nav-sub">
						{#each children_[item.path] ?? [] as child (child.href)}
							<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved path -->
							<a href={child.href} class:on={page.url.pathname === child.href}>{child.label}</a>
						{/each}
					</div>
				{/if}
			{/each}
		</nav>
		{@render sideExtra?.()}
		<div class="side-foot">
			{#each footLinks as link (link.href)}
				<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved href -->
				<a class="nav-i" href={link.href}>
					<span class="ic"><Icon name={link.icon} /></span>
					<span>{link.label}</span>
				</a>
			{/each}
		</div>
	</aside>
	<div class="scrim" role="presentation" onclick={closeSide}></div>
	<div class="main-col">
		<header class="topbar">
			<button
				class="icon-btn menu-btn"
				type="button"
				aria-label={tr('Otvori izbornik', 'Open menu')}
				onclick={openSide}><Icon name="menu" /></button
			>
			<form class="gs" role="search" onsubmit={search}>
				<label class="sr" for="gs-q">{tr('Traži', 'Search')}</label>
				<Icon name="search" size={16} />
				<input
					id="gs-q"
					class="in"
					name="q"
					type="search"
					placeholder={tr('Traži fotke, osobe, mjesta…', 'Search photos, people, places…')}
					autocomplete="off"
				/>
			</form>
			<div class="top-r">
				<LangMenu />
				<ThemeButton />
				<div class="me">
					<Avatar initials={initialsOf(user.name)} />
					<span class="me-t"><b>{user.name}</b><small>{roleLabel}</small></span>
				</div>
				<form class="inl" onsubmit={signOut}>
					<button
						class="icon-btn"
						title={tr('Odjava', 'Sign out')}
						aria-label={tr('Odjava', 'Sign out')}
					>
						<Icon name="out" />
					</button>
				</form>
			</div>
		</header>
		<main id="main" class="main" tabindex="-1">
			{@render children()}
		</main>
		<footer class="foot">© {new Date().getFullYear()} Mediarr · {footLabel}</footer>
	</div>
</div>
<CommandPalette items={nav} />
