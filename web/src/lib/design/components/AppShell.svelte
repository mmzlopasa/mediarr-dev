<script lang="ts">
	import type { Snippet } from 'svelte';
	import { afterNavigate, goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
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
		roleLabel,
		footLabel,
		footLink,
		children
	}: {
		nav: NavItem[];
		tag?: string;
		roleLabel: string;
		footLabel: string;
		footLink: { href: string; icon: 'photo' | 'shield'; label: string };
		children: Snippet;
	} = $props();

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
				<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- paths come from the static nav list -->
				<a href={item.path} class="nav-i" class:on aria-current={on ? 'page' : undefined}>
					<span class="ic"><Icon name={item.icon} /></span>
					<span>{tr(item.hr, item.en)}</span>
				</a>
			{/each}
		</nav>
		<div class="side-foot">
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved href -->
			<a class="nav-i" href={footLink.href}>
				<span class="ic"><Icon name={footLink.icon} /></span>
				<span>{footLink.label}</span>
			</a>
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
					<Avatar initials="DK" />
					<span class="me-t"
						><b>{tr('Demo korisnik', 'Demo user')}</b><small>{roleLabel}</small></span
					>
				</div>
				<form class="inl" method="get" action={resolve('/login')}>
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
