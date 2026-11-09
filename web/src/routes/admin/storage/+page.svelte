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
	import StorageTemplateCard from '#lib/organize/StorageTemplateCard.svelte';
	import { t } from '#lib/i18n.svelte.ts';
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
			showToast('err', t('admin.storage.enterANumberOfGb'));
			return;
		}
		try {
			await api.setQuota(id, value ? Math.round(number * GB) : undefined);
			showToast('ok', t('common.saved'));
			await loadUsers();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t('admin.storage.storage')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{t('admin.storage.storage')}</h1></div>
</div>

{#if overview.failed}
	<Alert kind="err">{t('common.theDataCouldNotBe')}</Alert>
{/if}
{#if overview.data}
	{@const data = overview.data}
	<Card title={t('admin.storage.libraryDisk')}>
		<Kv label={t('admin.storage.originals')} value={formatBytes(data.libraryBytes)} />
		<Kv label={t('admin.storage.freeDiskSpace')} value={formatBytes(data.diskFreeBytes)} />
		<Kv label={t('admin.storage.diskSize')} value={formatBytes(data.diskTotalBytes)} />
		<Bar pct={diskUsedPercent(data)} />
	</Card>
	{#if users}
		<Card title={t('admin.storage.byUser')}>
			<p class="alb-meta">
				{t('admin.storage.anExternalFolderDoesNot')}
			</p>
			{#each users as user (user.id)}
				<div class="alb-list" data-user={user.email}>
					<b>{user.name}</b>
					<span class="alb-meta"
						>{user.email} · {formatBytes(user.storedBytes)} · {user.assets}</span
					>
					<Input label={t('admin.storage.quotaInGb')} bind:value={limits[user.id]} />
					<Button small onclick={() => saveLimit(user.id)}>{t('common.save')}</Button>
				</div>
			{/each}
		</Card>
	{/if}
{:else if !overview.failed}
	<Skeleton height="220px" />
{/if}

<StorageTemplateCard />
