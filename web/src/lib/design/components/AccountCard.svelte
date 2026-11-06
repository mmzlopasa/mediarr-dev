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
	import { lang, languages, setLang, tr, type Lang } from '#lib/i18n.svelte.ts';
	import type { IconName } from '../icons.ts';
	import { setTheme, themeChoice, type ThemeChoice } from '../theme.ts';
	import Icon from './Icon.svelte';

	/*
	 * The account menu as a card: who is signed in, how big the library is, where to go, and how the
	 * app looks. Everything in it is live; the numbers wait for the server.
	 */
	let {
		user,
		roleLabel,
		links,
		onSignOut
	}: {
		user: User;
		roleLabel: string;
		links: { href: string; icon: IconName; label: string }[];
		onSignOut: (event: SubmitEvent) => void;
	} = $props();

	let stats = $state<AccountStats>();
	let failedJobs = $state(0);
	let theme = $state<ThemeChoice>(themeChoice());

	onMount(() => {
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

	const THEMES: { id: ThemeChoice; icon: IconName; hr: string; en: string }[] = [
		{ id: 'dark', icon: 'moon', hr: 'Tamno', en: 'Dark' },
		{ id: 'light', icon: 'sun', hr: 'Svijetlo', en: 'Light' },
		{ id: 'system', icon: 'monitor', hr: 'Sustav', en: 'System' }
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
		</div>
		{#if user.isAdmin}<span class="me-role">{roleLabel}</span>{/if}
	</div>

	<p class="me-lib" aria-live="polite">
		{#if stats}
			<span
				><b>{(stats.photos + stats.videos).toLocaleString()}</b>
				{tr('fotki i videa', 'photos and videos')}</span
			>
			<span><b>{formatBytes(stats.bytes)}</b> {tr('zauzeto', 'used')}</span>
		{:else}
			<span class="me-wait"></span>
		{/if}
	</p>

	<nav class="me-go" aria-label={tr('Račun', 'Account')}>
		{#each links as link (link.href)}
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the caller supplies a resolved href -->
			<a href={link.href}>
				<Icon name={link.icon} size={18} /><span>{link.label}</span>
				{#if link.icon === 'shield' && failedJobs > 0}
					<em class="me-alert">{tr(`${failedJobs} neuspjelo`, `${failedJobs} failed`)}</em>
				{/if}
			</a>
		{/each}
		<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- a fixed route -->
		<a href="/tv"><Icon name="tv" size={18} /><span>{tr('TV način', 'TV mode')}</span></a>
	</nav>

	<div class="me-set">
		<span class="me-l" id="me-theme">{tr('Izgled', 'Appearance')}</span>
		<div class="me-seg" role="radiogroup" aria-labelledby="me-theme">
			{#each THEMES as option (option.id)}
				<button
					type="button"
					role="radio"
					aria-checked={theme === option.id}
					class:on={theme === option.id}
					onclick={() => pickTheme(option.id)}
					><Icon name={option.icon} size={15} /><span>{tr(option.hr, option.en)}</span></button
				>
			{/each}
		</div>
		<label class="me-l" for="me-lang">{tr('Jezik', 'Language')}</label>
		<select
			id="me-lang"
			class="me-sel"
			value={lang()}
			onchange={(event) => setLang(event.currentTarget.value as Lang)}
		>
			{#each Object.entries(languages) as [code, name] (code)}
				<option value={code}>{name}</option>
			{/each}
		</select>
	</div>

	<form onsubmit={onSignOut}>
		<button class="me-out" type="submit"
			><Icon name="out" size={18} /><span>{tr('Odjava', 'Sign out')}</span></button
		>
	</form>
</div>
