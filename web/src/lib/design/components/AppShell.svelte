<script lang="ts">
	import { onMount } from 'svelte';
	import type { Snippet } from 'svelte';
	import { afterNavigate, goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, ApiError, avatarOf, initialsOf, type User } from '#lib/api.ts';
	import { showToast } from './toast.svelte.ts';
	import NotificationBell from '#lib/organize/NotificationBell.svelte';
	import type { IconName } from '../icons.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import AccountCard from './AccountCard.svelte';
	import QRSignInDialog from '#lib/devices/QRSignInDialog.svelte';
	import Avatar from './Avatar.svelte';
	import CommandPalette from './CommandPalette.svelte';
	import Icon from './Icon.svelte';
	import Logo from './Logo.svelte';
	import UploadButton from './UploadButton.svelte';
	import { directMotion } from '#lib/motion/director.ts';
	import { startSmoothScroll } from '#lib/motion/motion.ts';

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
	let qrOpen = $state(false);
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

	let main = $state<HTMLElement>();

	onMount(() => {
		const onMaintenance = () => (maintained = true);
		window.addEventListener('mediarr:maintenance', onMaintenance);
		let stopScroll: (() => void) | undefined;
		let stopped = false;
		void startSmoothScroll().then((stop) => {
			if (stopped) stop();
			else stopScroll = stop;
		});
		const stopMotion = main ? directMotion(main) : undefined;
		return () => {
			stopped = true;
			stopScroll?.();
			stopMotion?.();
			window.removeEventListener('mediarr:maintenance', onMaintenance);
		};
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
		try {
			await api.logout();
		} catch (cause) {
			// A session that has already ended is signed out; anything else did not happen.
			if (!(cause instanceof ApiError && cause.status === 401)) {
				showToast('err', t('appShell.signOutFailed'));
				return;
			}
		}
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

<a class="skip" href="#main">{t('appShell.skipToContent')}</a>
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
					aria-label={t('common.account')}
					onclick={() => (meOpen = !meOpen)}
				>
					<Avatar initials={initialsOf(user.name)} src={avatarOf(user)} />
				</button>
				{#if meOpen}
					<div class="lb-pop lb-me-m" data-lenis-prevent>
						<AccountCard
							{user}
							{roleLabel}
							links={footLinks}
							onSignOut={signOut}
							onPhoneSignIn={() => {
								meOpen = false;
								qrOpen = true;
							}}
						/>
					</div>
				{/if}
			</div>
		</div>
	</header>

	{#if admin}
		<nav class="lb-side" aria-label={t('appShell.navigation')}>
			{#each nav as item (item.path)}
				<!-- eslint-disable svelte/no-navigation-without-resolve -- paths come from the static nav list -->
				<a
					href={item.path}
					class="lb-side-i"
					class:on={current(item.path)}
					aria-current={current(item.path) ? 'page' : undefined}
				>
					<Icon name={item.icon} /><span>{t(item.label)}</span>
				</a>
				<!-- eslint-enable svelte/no-navigation-without-resolve -->
			{/each}
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
			<a href="/" class="lb-side-i lb-side-back"
				><Icon name="photo" /><span>{t('appShell.backToMedia')}</span></a
			>
		</nav>
	{:else}
		<nav class="lb-dock" aria-label={t('appShell.navigation')}>
			{#each docked as item (item.path)}
				<!-- eslint-disable svelte/no-navigation-without-resolve -- paths come from the static nav list -->
				<a
					href={item.path}
					class="lb-dock-i"
					class:on={current(item.path)}
					aria-current={current(item.path) ? 'page' : undefined}
				>
					<Icon name={item.icon} /><span>{t(item.label)}</span>
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
					<Icon name="grid" /><span>{t('appShell.more')}</span>
				</button>
			{/if}
			<form class="lb-ask" role="search" onsubmit={search}>
				<label class="sr" for="gs-q">{t('appShell.search')}</label>
				<Icon name="search" size={18} />
				<input
					id="gs-q"
					name="q"
					type="search"
					placeholder={t('appShell.askYourPhotos')}
					autocomplete="off"
				/>
				<button type="button" class="lb-kbd" onclick={() => palette?.open()}>⌘K</button>
			</form>
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
			<a href="/search" class="lb-dock-i lb-ask-m" aria-label={t('appShell.search')}
				><Icon name="search" /></a
			>
			<span class="lb-add"><UploadButton compact /></span>
			{#if moreOpen}
				<div class="lb-pop lb-more" data-lenis-prevent>
					<div class="lb-more-g">
						{#each more as item (item.path)}
							<!-- eslint-disable svelte/no-navigation-without-resolve -- paths come from the static nav list -->
							<a
								href={item.path}
								class="lb-more-i"
								class:on={current(item.path)}
								aria-current={current(item.path) ? 'page' : undefined}
							>
								<Icon name={item.icon} /><span>{t(item.label)}</span>
							</a>
							<!-- eslint-enable svelte/no-navigation-without-resolve -->
						{/each}
					</div>
					{@render sideExtra?.()}
				</div>
			{/if}
		</nav>
	{/if}

	<main id="main" class="main" tabindex="-1" bind:this={main}>
		{#if maintained}
			<p class="maintenance" role="status">
				{t('appShell.thisServerIsBeingMaintained')}
			</p>
		{/if}
		{@render children()}
	</main>
</div>
<CommandPalette bind:this={palette} items={nav} />
<QRSignInDialog bind:open={qrOpen} />
