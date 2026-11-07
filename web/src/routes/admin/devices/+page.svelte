<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type BackupDevice } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import DeviceList from '#lib/devices/DeviceList.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

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

<svelte:head><title>{tr('Uređaji za backup', 'Backup devices')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr('Uređaji za backup', 'Backup devices')}</h1>
		<p>
			{tr(
				'Uređaji svih korisnika koji rade backup. Upozorenje kad uređaj šuti dobiva njegov vlasnik.',
				'Every user’s devices that back up. When one goes quiet, its owner is warned.'
			)}
		</p>
	</div>
</div>

<Card
	id="devices"
	title={devices && quiet
		? tr(`Svi uređaji · ${quiet} šuti`, `All devices · ${quiet} quiet`)
		: tr('Svi uređaji', 'All devices')}
>
	{#if devices === undefined}
		<Skeleton height="96px" />
	{:else if failed}
		<p class="alb-meta">{tr('Uređaji nisu učitani.', 'The devices did not load.')}</p>
	{:else if devices.length === 0}
		<p class="alb-meta">{tr('Još nijedan uređaj nije javio.', 'No device has reported yet.')}</p>
	{:else}
		<DeviceList {devices} owners />
	{/if}
</Card>
