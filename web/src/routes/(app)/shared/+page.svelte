<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { api, type Album, type Partners, type UserRef } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, t } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';

	const POLL_MS = 10000;
	const item = appNav.find((candidate) => candidate.path === '/shared') ?? appNav[0];

	let albums = $state<Album[]>();
	let partners = $state<Partners>();
	let users = $state<UserRef[]>([]);
	let failed = $state(false);
	let userId = $state('');
	let since = $state('');

	const locale = $derived(lang() === 'hr' ? 'hr-HR' : 'en-GB');
	const withMe = $derived((albums ?? []).filter((album) => album.role !== 'owner'));
	const free = $derived(
		users.filter((user) => !partners?.given.some((entry) => entry.userId === user.id))
	);

	async function load() {
		try {
			[albums, partners, users] = await Promise.all([
				api.albums(),
				api.partners(),
				api.directory()
			]);
			failed = false;
		} catch {
			failed = true;
		}
	}

	onMount(() => {
		load();
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	async function run(action: () => Promise<void>) {
		try {
			await action();
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	const start = () =>
		run(async () => {
			await api.setPartner(userId, since || undefined);
			userId = since = '';
		});

	const sinceLabel = (value: string | undefined) =>
		value
			? t('shared.from') + new Date(value).toLocaleDateString(locale)
			: t('shared.wholeLibrary');
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{t(item.label)}</h1></div>
</div>

{#if failed}
	<Alert kind="err">{t('common.theDataCouldNotBe')}</Alert>
{/if}

{#if !albums || !partners}
	{#if !failed}<Skeleton height="200px" />{/if}
{:else}
	<Card title={t('shared.albumsSharedWithMe')}>
		{#each withMe as album (album.id)}
			<div class="alb-list">
				<b><a href={resolve('/(app)/albums/[id]', { id: album.id })}>{album.title}</a></b>
				<span class="alb-meta">{album.ownerName} · {album.assetCount}</span>
			</div>
		{:else}
			<EmptyState icon="album" text={item.empty ? t(item.empty) : ''} />
		{/each}
	</Card>

	<Card title={t('shared.librariesSharedWithMe')}>
		{#each partners.received as entry (entry.userId)}
			<div class="alb-list">
				<b><a href={resolve('/(app)/partners/[id]', { id: entry.userId })}>{entry.name}</a></b>
				<span class="alb-meta">{sinceLabel(entry.since)}</span>
				<Button
					small
					onclick={() => run(() => api.setPartnerTimeline(entry.userId, !entry.inTimeline))}
					>{entry.inTimeline ? t('shared.removeFromMyMedia') : t('shared.showInMyMedia')}</Button
				>
			</div>
		{:else}
			<p class="alb-meta">
				{t('shared.nobodySharesTheirLibraryWith')}
			</p>
		{/each}
	</Card>

	<Card title={t('shared.myLibraryIsSharedWith')}>
		{#each partners.given as entry (entry.userId)}
			<div class="alb-list">
				<b>{entry.name}</b>
				<span class="alb-meta">{sinceLabel(entry.since)}</span>
				<Button small onclick={() => run(() => api.removePartner(entry.userId))}
					>{t('shared.stop')}</Button
				>
			</div>
		{:else}
			<p class="alb-meta">{t('shared.nobodyYet')}</p>
		{/each}
		{#if free.length > 0}
			<div class="form">
				<Select
					label={t('common.user')}
					bind:value={userId}
					options={[
						{ value: '', label: t('shared.choose') },
						...free.map((user) => ({ value: user.id, label: user.name }))
					]}
				/>
				<Input
					label={t('common.fromDate')}
					hint={t('shared.emptyMeansTheWholeLibrary')}
					type="date"
					bind:value={since}
				/>
				<Button small variant="gold" disabled={!userId} onclick={start}
					>{t('shared.shareMyLibrary')}</Button
				>
			</div>
		{/if}
	</Card>
{/if}
