<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type BackupDeviceList } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import DeviceList from '#lib/devices/DeviceList.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let list = $state<BackupDeviceList>();

	onMount(async () => {
		try {
			list = await api.backupDevices();
		} catch {
			list = { devices: [], quietDays: 3 };
			showToast('err', tr('Uređaji nisu učitani.', 'The devices did not load.'));
		}
	});

	async function setDays(days: number) {
		try {
			await api.setBackupQuietDays(days);
			list = await api.backupDevices();
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		}
	}
</script>

<svelte:head><title>{tr('Uređaji za backup', 'Backup devices')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr('Uređaji za backup', 'Backup devices')}</h1>
		<p>
			{tr(
				'Mobiteli koji rade backup, i koliko je s njih sigurno na serveru. Broji server, prema vlastitim datotekama.',
				'Phones that back up, and how much from each is safe on the server. The server counts, from its own files.'
			)}
		</p>
	</div>
</div>

<div class="imp">
	<Card id="devices" title={tr('Vaši uređaji', 'Your devices')}>
		{#if list === undefined}
			<Skeleton height="96px" />
		{:else if list.devices.length === 0}
			<p class="alb-meta">
				{tr(
					'Još nijedan uređaj nije javio. Uključite backup u aplikaciji Mediarr na mobitelu.',
					'No device has reported yet. Turn on backup in the Mediarr app on your phone.'
				)}
			</p>
		{:else}
			<DeviceList
				devices={list.devices}
				onRemoved={(id) => list && (list.devices = list.devices.filter((d) => d.id !== id))}
			/>
		{/if}
	</Card>
	<Card id="quiet" title={tr('Upozorenje', 'Warning')}>
		<label class="set-row">
			<span
				>{tr(
					'Upozori me kad se uređaj ne javi',
					'Warn me when a device has not reported for'
				)}</span
			>
			<select
				class="in"
				aria-label={tr('Upozori nakon', 'Warn after')}
				value={String(list?.quietDays ?? 3)}
				disabled={list === undefined}
				onchange={(event) => setDays(Number(event.currentTarget.value))}
			>
				{#each [1, 3, 7, 14] as days (days)}
					<option value={String(days)}
						>{days === 1 ? tr('1 dan', '1 day') : tr(`${days} dana`, `${days} days`)}</option
					>
				{/each}
				<option value="0">{tr('Nikad', 'Never')}</option>
			</select>
		</label>
		<p class="alb-meta">
			{tr(
				'Obavijest stiže ovdje i u aplikaciji, i e-mailom ako ga je administrator postavio. Jednom, dok se uređaj opet ne javi.',
				'The notice comes here and in the app, and by e-mail if the administrator set it up. Once, until the device reports again.'
			)}
		</p>
	</Card>
</div>
