<script lang="ts">
	import { onMount } from 'svelte';
	import {
		api,
		avatarOf,
		formatBytes,
		initialsOf,
		type AccountStats,
		type User
	} from '#lib/api.ts';
	import { lang, languages, type Lang, t, k, type Key } from '#lib/i18n.svelte.ts';
	import type { IconName } from '../icons.ts';
	import { setTheme, themeChoice, type ThemeChoice } from '../theme.ts';
	import Icon from './Icon.svelte';
	import { chooseLang } from '#lib/language.ts';

	/*
	 * The account menu as a card: who is signed in, how big the library is, where to go, and how the
	 * app looks. Everything in it is live; the numbers wait for the server.
	 */
	let {
		user,
		roleLabel,
		links,
		onSignOut,
		onPhoneSignIn
	}: {
		user: User;
		roleLabel: string;
		links: { href: string; icon: IconName; label: string }[];
		onSignOut: (event: SubmitEvent) => void;
		onPhoneSignIn?: () => void;
	} = $props();

	let stats = $state<AccountStats>();
	let failedJobs = $state(0);
	let serverName = $state<string>();
	let theme = $state<ThemeChoice>(themeChoice());

	onMount(() => {
		api
			.authMethods()
			.then((methods) => (serverName = methods.serverName))
			.catch(() => undefined);
		api
			.myStats()
			.then((value) => (stats = value))
			.catch(() => undefined);
		if (user.isAdmin) {
			api
				.adminOverview()
				.then((value) => (failedJobs = value.jobs.failed))
				.catch(() => undefined);
		}
	});

	const THEMES: { id: ThemeChoice; icon: IconName; label: Key }[] = [
		{ id: 'dark', icon: 'moon', label: k('accountCard.dark') },
		{ id: 'light', icon: 'sun', label: k('accountCard.light') },
		{ id: 'system', icon: 'monitor', label: k('admin.system') }
	];

	function pickTheme(choice: ThemeChoice) {
		theme = choice;
		setTheme(choice);
	}
</script>

<div class="me">
	<div class="me-who">
		<span class="me-av" aria-hidden="true"
			>{#if avatarOf(user)}<img src={avatarOf(user)} alt="" />{:else}{initialsOf(
					user.name
				)}{/if}</span
		>
		<div class="me-id">
			<b>{user.name}</b>
			<small>{user.email}</small>
			{#if serverName && serverName !== 'Mediarr'}<small class="me-srv"
					>{t('accountCard.onServername', { serverName })}</small
				>{/if}
		</div>
		{#if user.isAdmin}<span class="me-role">{roleLabel}</span>{/if}
	</div>

	<p class="me-lib" aria-live="polite">
		{#if stats}
			<span
				><b>{(stats.photos + stats.videos).toLocaleString()}</b>
				{t('accountCard.photosAndVideos')}</span
			>
			<span><b>{formatBytes(stats.bytes)}</b> {t('accountCard.used')}</span>
		{:else}
			<span class="me-wait"></span>
		{/if}
	</p>

	<nav class="me-go" aria-label={t('common.account')}>
		{#each links as link (link.href)}
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved href -->
			<a href={link.href}>
				<Icon name={link.icon} size={18} /><span>{link.label}</span>
				{#if link.icon === 'shield' && failedJobs > 0}
					<em class="me-alert">{t('accountCard.failedjobsFailed', { failedJobs })}</em>
				{/if}
			</a>
		{/each}
		<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
		<a href="/tv"><Icon name="tv" size={18} /><span>{t('accountCard.tvMode')}</span></a>
		{#if onPhoneSignIn}
			<button type="button" onclick={onPhoneSignIn}
				><Icon name="phone" size={18} /><span>{t('accountCard.signInOnAPhone')}</span></button
			>
		{/if}
	</nav>

	<div class="me-set">
		<span class="me-l" id="me-theme">{t('accountCard.appearance')}</span>
		<div class="me-seg" role="radiogroup" aria-labelledby="me-theme">
			{#each THEMES as option (option.id)}
				<button
					type="button"
					role="radio"
					aria-checked={theme === option.id}
					class:on={theme === option.id}
					onclick={() => pickTheme(option.id)}
					><Icon name={option.icon} size={15} /><span>{t(option.label)}</span></button
				>
			{/each}
		</div>
		<label class="me-l" for="me-lang">{t('accountCard.language')}</label>
		<select
			id="me-lang"
			class="me-sel"
			value={lang()}
			onchange={(event) => chooseLang(event.currentTarget.value as Lang)}
		>
			{#each Object.entries(languages) as [code, name] (code)}
				<option value={code}>{name}</option>
			{/each}
		</select>
	</div>

	<form onsubmit={onSignOut}>
		<button class="me-out" type="submit"
			><Icon name="out" size={18} /><span>{t('accountCard.signOut')}</span></button
		>
	</form>
</div>
