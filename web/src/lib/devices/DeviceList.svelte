<script lang="ts">
	import { api, type BackupDevice, type BackupDeviceMissing } from '#lib/api.ts';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, tr } from '#lib/i18n.svelte.ts';
	import { since } from '#lib/organize/agent.ts';

	/** Phones that back up, with what the server itself counts as safe from each. */
	let {
		devices,
		owners = false,
		onRemoved
	}: { devices: BackupDevice[]; owners?: boolean; onRemoved?: (id: string) => void } = $props();

	let missing = $state<Record<string, BackupDeviceMissing>>({});
	const number = (value: number) => value.toLocaleString(lang() === 'hr' ? 'hr' : 'en');
	const total = (d: BackupDevice) => d.pending + d.working + d.verified + d.failed;
	const pct = (d: BackupDevice) => (total(d) ? Math.round((d.verified / total(d)) * 100) : 100);
	const system = (platform: string) =>
		({ ios: 'iOS', android: 'Android' })[platform.toLowerCase()] ?? platform;

	async function toggleMissing(id: string) {
		if (missing[id]) {
			delete missing[id];
			return;
		}
		try {
			missing[id] = await api.backupDeviceMissing(id);
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : tr('Nije učitano.', 'Not loaded.'));
		}
	}

	async function remove(device: BackupDevice) {
		const ask = tr(
			`Maknuti „${device.name}” s popisa? Fotke ostaju na serveru. Ako uređaj opet javi, vratit će se.`,
			`Take “${device.name}” off the list? Its photos stay on the server. If it reports again, it comes back.`
		);
		if (!confirm(ask)) return;
		try {
			await api.removeBackupDevice(device.id);
			onRemoved?.(device.id);
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije maknuto.', 'Not removed.')
			);
		}
	}
</script>

<ul class="set-list dev-list" aria-label={tr('Uređaji', 'Devices')}>
	{#each devices as device (device.id)}
		{@const unsafe = device.gone + device.trashed}
		<li class="dev" class:quiet={device.quiet} data-device={device.name}>
			<span class="dev-ic"><Icon name="phone" size={18} /></span>
			<span class="set-list-t">
				<b>
					{device.name || tr('Uređaj', 'Device')}
					{#if device.quiet}
						<em class="set-chip err">{tr('Šuti', 'Quiet')}</em>
					{:else if device.failed > 0 || unsafe > 0}
						<em class="set-chip">{tr('Treba pogledati', 'Needs a look')}</em>
					{:else}
						<em class="set-chip ok">{tr('U redu', 'All good')}</em>
					{/if}
				</b>
				<small>
					{#if owners}{device.ownerName
							? `${device.ownerName} (${device.ownerEmail})`
							: device.ownerEmail} ·
					{/if}{system(device.platform)}{device.appVersion ? ` · Mediarr ${device.appVersion}` : ''} ·
					{tr('zadnje javljanje', 'last report')}
					<time datetime={device.reportedAt} title={new Date(device.reportedAt).toLocaleString()}
						>{since(new Date(device.reportedAt))}</time
					>
				</small>
				<span class="dev-safe">
					<strong>{number(device.confirmed)}</strong>
					{tr('datoteka potvrdio je server', 'files confirmed by the server')}
					{#if device.files > device.confirmed}
						<span class="dev-of">
							{tr('od', 'of')}
							{number(device.files)}
							{tr('koje je uređaj poslao', 'the device sent')}</span
						>
					{/if}
				</span>
				<Bar
					pct={pct(device)}
					progress
					label={tr(
						`${number(device.verified)} od ${number(total(device))} na uređaju`,
						`${number(device.verified)} of ${number(total(device))} on the device`
					)}
				/>
				<small class="dev-counts">
					{tr('čeka', 'waiting')}
					{number(device.pending + device.working)} · {tr('nije poslano', 'not sent')}
					{number(device.failed)}
					{#if device.trashed}
						· {tr('u smeću', 'in the trash')} {number(device.trashed)}{/if}
					{#if device.gone}
						· {tr('više nije na serveru', 'no longer on the server')} {number(device.gone)}{/if}
				</small>
				{#if device.quiet}
					<p class="dev-warn">
						{tr(
							'Uređaj se nije javio dulje nego što ste odredili. Otvorite Mediarr na njemu i provjerite je li backup uključen.',
							'The device has not reported for longer than you allow. Open Mediarr on it and check that backup is on.'
						)}
					</p>
				{/if}
				{#if missing[device.id]}
					{@const m = missing[device.id]}
					<div class="imp-report">
						{#if m.failures.length === 0 && m.gone.length === 0}
							<p>{tr('Ništa ne nedostaje.', 'Nothing is missing.')}</p>
						{:else}
							<ul>
								{#each m.failures as failure, n (n)}
									<li><b class="mono">{failure.name}</b> {failure.reason}</li>
								{/each}
								{#each m.gone as gone (gone.checksum)}
									<li>
										<b class="mono">{gone.name || gone.checksum.slice(0, 12)}</b>
										{gone.inTrash
											? tr('je u smeću na serveru.', 'is in the trash on the server.')
											: tr('je obrisana sa servera.', 'was deleted from the server.')}
									</li>
								{/each}
							</ul>
						{/if}
					</div>
				{/if}
			</span>
			{#if !owners}
				<span class="imp-acts">
					{#if device.failed > 0 || unsafe > 0}
						<Button small onclick={() => toggleMissing(device.id)}
							>{missing[device.id]
								? tr('Sakrij', 'Hide')
								: tr('Što nedostaje', 'What is missing')}</Button
						>
					{/if}
					<Button small variant="danger" onclick={() => remove(device)}
						>{tr('Makni', 'Remove')}</Button
					>
				</span>
			{/if}
		</li>
	{/each}
</ul>
