<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type BackupDevice } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import DeviceList from '#lib/devices/DeviceList.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	let devices = $state<BackupDevice[]>();
	let failed = $state(false);
	const quiet = $derived(devices?.filter((d) => d.quiet).length ?? 0);

	onMount(async () => {
		try {
			devices = (await api.allBackupDevices()).devices;
		} catch {
			failed = true;
			devices = [];
		}
	});
</script>

<svelte:head><title>{t('common.backupDevices')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t('common.backupDevices')}</h1>
		<p>
			{t('admin.devices.everyUserSDevicesThat')}
		</p>
	</div>
</div>

<Card
	id="devices"
	title={devices && quiet
		? t('admin.devices.allDevicesQuietQuiet', { quiet })
		: t('admin.devices.allDevices')}
>
	{#if devices === undefined}
		<Skeleton height="96px" />
	{:else if failed}
		<p class="alb-meta">{t('admin.devices.theDevicesDidNotLoad')}</p>
	{:else if devices.length === 0}
		<p class="alb-meta">{t('admin.devices.noDeviceHasReportedYet')}</p>
	{:else}
		<DeviceList {devices} owners />
	{/if}
</Card>
