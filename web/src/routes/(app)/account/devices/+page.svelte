<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type BackupDeviceList } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import DeviceList from '#lib/devices/DeviceList.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	let list = $state<BackupDeviceList>();

	onMount(async () => {
		try {
			list = await api.backupDevices();
		} catch {
			list = { devices: [], quietDays: 3 };
			showToast('err', t('account.devices.theDevicesDidNotLoad'));
		}
	});

	async function setDays(days: number) {
		try {
			await api.setBackupQuietDays(days);
			list = await api.backupDevices();
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
	}
</script>

<svelte:head><title>{t('common.backupDevices')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t('common.backupDevices')}</h1>
		<p>
			{t('account.devices.phonesThatBackUpAnd')}
		</p>
	</div>
</div>

<div class="imp">
	<Card id="devices" title={t('account.devices.yourDevices')}>
		{#if list === undefined}
			<Skeleton height="96px" />
		{:else if list.devices.length === 0}
			<p class="alb-meta">
				{t('account.devices.noDeviceHasReportedYet')}
			</p>
		{:else}
			<DeviceList
				devices={list.devices}
				onRemoved={(id) => list && (list.devices = list.devices.filter((d) => d.id !== id))}
			/>
		{/if}
	</Card>
	<Card id="quiet" title={t('account.devices.warning')}>
		<label class="set-row">
			<span>{t('account.devices.warnMeWhenADevice')}</span>
			<select
				class="in"
				aria-label={t('account.devices.warnAfter')}
				value={String(list?.quietDays ?? 3)}
				disabled={list === undefined}
				onchange={(event) => setDays(Number(event.currentTarget.value))}
			>
				{#each [1, 3, 7, 14] as days (days)}
					<option value={String(days)}
						>{days === 1
							? t('account.devices.1Day')
							: t('account.devices.daysDays', { days })}</option
					>
				{/each}
				<option value="0">{t('account.devices.never')}</option>
			</select>
		</label>
		<p class="alb-meta">
			{t('account.devices.theNoticeComesHereAnd')}
		</p>
	</Card>
</div>
