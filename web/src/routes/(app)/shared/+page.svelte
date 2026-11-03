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
	import { lang, tr } from '#lib/i18n.svelte.ts';
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
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	const start = () =>
		run(async () => {
			await api.setPartner(userId, since || undefined);
			userId = since = '';
		});

	const sinceLabel = (value: string | undefined) =>
		value
			? tr('od ', 'from ') + new Date(value).toLocaleDateString(locale)
			: tr('cijela biblioteka', 'whole library');
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
</div>

{#if failed}
	<Alert kind="err">{tr('Podaci se nisu učitali.', 'The data could not be loaded.')}</Alert>
{/if}

{#if !albums || !partners}
	{#if !failed}<Skeleton height="200px" />{/if}
{:else}
	<Card title={tr('Albumi podijeljeni sa mnom', 'Albums shared with me')}>
		{#each withMe as album (album.id)}
			<div class="alb-list">
				<b><a href={resolve('/(app)/albums/[id]', { id: album.id })}>{album.title}</a></b>
				<span class="alb-meta">{album.ownerName} · {album.assetCount}</span>
			</div>
		{:else}
			<EmptyState icon="album" text={tr(item.emptyHr, item.emptyEn)} />
		{/each}
	</Card>

	<Card title={tr('Biblioteke podijeljene sa mnom', 'Libraries shared with me')}>
		{#each partners.received as entry (entry.userId)}
			<div class="alb-list">
				<b><a href={resolve('/(app)/partners/[id]', { id: entry.userId })}>{entry.name}</a></b>
				<span class="alb-meta">{sinceLabel(entry.since)}</span>
				<Button
					small
					onclick={() => run(() => api.setPartnerTimeline(entry.userId, !entry.inTimeline))}
					>{entry.inTimeline
						? tr('Makni iz mojih Fotki', 'Remove from my Photos')
						: tr('Prikaži u mojim Fotkama', 'Show in my Photos')}</Button
				>
			</div>
		{:else}
			<p class="alb-meta">
				{tr('Nitko s vama ne dijeli svoju biblioteku.', 'Nobody shares their library with you.')}
			</p>
		{/each}
	</Card>

	<Card title={tr('Moja biblioteka je podijeljena s', 'My library is shared with')}>
		{#each partners.given as entry (entry.userId)}
			<div class="alb-list">
				<b>{entry.name}</b>
				<span class="alb-meta">{sinceLabel(entry.since)}</span>
				<Button small onclick={() => run(() => api.removePartner(entry.userId))}
					>{tr('Prekini', 'Stop')}</Button
				>
			</div>
		{:else}
			<p class="alb-meta">{tr('Još ni s kim.', 'Nobody yet.')}</p>
		{/each}
		{#if free.length > 0}
			<div class="form">
				<Select
					label={tr('Korisnik', 'User')}
					bind:value={userId}
					options={[
						{ value: '', label: tr('Odaberi', 'Choose') },
						...free.map((user) => ({ value: user.id, label: user.name }))
					]}
				/>
				<Input
					label={tr('Od datuma', 'From date')}
					hint={tr(
						'Prazno znači cijela biblioteka. Arhiva, smeće i trezor se nikad ne dijele.',
						'Empty means the whole library. The archive, trash and vault are never shared.'
					)}
					type="date"
					bind:value={since}
				/>
				<Button small variant="gold" disabled={!userId} onclick={start}
					>{tr('Podijeli biblioteku', 'Share my library')}</Button
				>
			</div>
		{/if}
	</Card>
{/if}
