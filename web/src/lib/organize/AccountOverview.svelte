<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AccountStats, type UserSession } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let stats = $state<AccountStats>();
	let sessions = $state<UserSession[]>();

	async function load() {
		try {
			[stats, sessions] = await Promise.all([api.myStats(), api.mySessions()]);
		} catch {
			showToast('err', tr('Podaci se ne mogu učitati.', 'This could not be loaded.'));
		}
	}

	async function act(work: () => Promise<unknown>) {
		try {
			await work();
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	onMount(load);
</script>

<Card title={tr('Statistika', 'Your library')}>
	{#if stats}
		<div class="acct-stats">
			<div><b>{stats.photos}</b><small>{tr('Fotke', 'Photos')}</small></div>
			<div><b>{stats.videos}</b><small>{tr('Videi', 'Videos')}</small></div>
			<div><b>{stats.albums}</b><small>{tr('Albumi', 'Albums')}</small></div>
			<div><b>{stats.favorites}</b><small>{tr('Favoriti', 'Favorites')}</small></div>
			<div><b>{stats.archived}</b><small>{tr('Arhiva', 'Archive')}</small></div>
			<div><b>{stats.trashed}</b><small>{tr('Smeće', 'Trash')}</small></div>
			<div><b>{formatBytes(stats.bytes)}</b><small>{tr('Zauzeto', 'Used')}</small></div>
		</div>
	{:else}
		<Skeleton height="72px" />
	{/if}
</Card>

<Card title={tr('Prijavljeni uređaji', 'Signed-in devices')}>
	{#if sessions}
		<div class="audit-list">
			{#each sessions as session (session.id)}
				<div class="audit-row">
					<small>{new Date(session.lastSeenAt).toLocaleString()}</small>
					<b>{session.current ? tr('Ovaj uređaj', 'This device') : session.ip}</b>
					<span>{session.userAgent}</span>
					<span>
						{#if !session.current}
							<Button small onclick={() => act(() => api.endSession(session.id))}>
								{tr('Odjavi', 'Sign out')}
							</Button>
						{/if}
					</span>
				</div>
			{/each}
		</div>
		{#if sessions.length > 1}
			<Button small onclick={() => act(() => api.endOtherSessions())}>
				{tr('Odjavi sve ostale', 'Sign out all the others')}
			</Button>
		{/if}
	{:else}
		<Skeleton height="72px" />
	{/if}
</Card>
