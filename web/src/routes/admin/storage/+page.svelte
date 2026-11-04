<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type UserStorage } from '#lib/api.ts';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { formatBytes } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { diskUsedPercent, liveOverview } from '#lib/overview.svelte.ts';

	const overview = liveOverview();

	const GB = 1024 * 1024 * 1024;
	let users = $state<UserStorage[]>();
	let limits = $state<Record<string, string>>({});

	async function loadUsers() {
		try {
			users = await api.adminStorage();
			limits = Object.fromEntries(
				users.map((user) => [
					user.id,
					user.quotaBytes === undefined ? '' : String(user.quotaBytes / GB)
				])
			);
		} catch {
			users = undefined;
		}
	}

	onMount(loadUsers);

	async function saveLimit(id: string) {
		const value = limits[id]?.trim();
		const number = Number(value);
		if (value && (!Number.isFinite(number) || number < 0)) {
			showToast('err', tr('Upišite broj GB.', 'Enter a number of GB.'));
			return;
		}
		try {
			await api.setQuota(id, value ? Math.round(number * GB) : undefined);
			showToast('ok', tr('Spremljeno.', 'Saved.'));
			await loadUsers();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr('Pohrana', 'Storage')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{tr('Pohrana', 'Storage')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{tr('Podaci se nisu učitali.', 'The data could not be loaded.')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={tr('Disk biblioteke', 'Library disk')}>
		<Kv label={tr('Originali', 'Originals')} value={formatBytes(data.libraryBytes)} />
		<Kv
			label={tr('Slobodno na disku', 'Free disk space')}
			value={formatBytes(data.diskFreeBytes)}
		/>
		<Kv label={tr('Veličina diska', 'Disk size')} value={formatBytes(data.diskTotalBytes)} />
		<Bar pct={diskUsedPercent(data)} />
	</Card>
	{#if users}
		<Card title={tr('Po korisniku', 'By user')}>
			<p class="alb-meta">
				{tr(
					'Vanjska mapa se ne računa u kvotu. Prazno polje znači bez ograničenja.',
					'An external folder does not count towards a quota. An empty field means no limit.'
				)}
			</p>
			{#each users as user (user.id)}
				<div class="alb-list" data-user={user.email}>
					<b>{user.name}</b>
					<span class="alb-meta"
						>{user.email} · {formatBytes(user.storedBytes)} · {user.assets}</span
					>
					<Input label={tr('Kvota u GB', 'Quota in GB')} bind:value={limits[user.id]} />
					<Button small onclick={() => saveLimit(user.id)}>{tr('Spremi', 'Save')}</Button>
				</div>
			{/each}
		</Card>
	{/if}
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}
