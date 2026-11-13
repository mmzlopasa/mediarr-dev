<script lang="ts">
	import { api, type BackupDevice, type BackupDeviceMissing } from '#lib/api.ts';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { dateLocale, lang, t } from '#lib/i18n.svelte.ts';
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
			showToast('err', cause instanceof Error ? cause.message : t('deviceList.notLoaded'));
		}
	}

	async function remove(device: BackupDevice) {
		const ask = t('deviceList.takeNameOffTheList', { name: device.name });
		if (!confirm(ask)) return;
		try {
			await api.removeBackupDevice(device.id);
			onRemoved?.(device.id);
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('deviceList.notRemoved'));
		}
	}
</script>

<ul class="set-list dev-list" aria-label={t('common.devices')}>
	{#each devices as device (device.id)}
		{@const unsafe = device.gone + device.trashed}
		<li class="dev" class:quiet={device.quiet} data-device={device.name}>
			<span class="dev-ic"><Icon name="phone" size={18} /></span>
			<span class="set-list-t">
				<b>
					{device.name || t('deviceList.device')}
					{#if device.quiet}
						<em class="set-chip err">{t('deviceList.quiet')}</em>
					{:else if device.failed > 0 || unsafe > 0}
						<em class="set-chip">{t('deviceList.needsALook')}</em>
					{:else}
						<em class="set-chip ok">{t('deviceList.allGood')}</em>
					{/if}
				</b>
				<small>
					{#if owners}{device.ownerName
							? `${device.ownerName} (${device.ownerEmail})`
							: device.ownerEmail} ·
					{/if}{system(device.platform)}{device.appVersion ? ` · Mediarr ${device.appVersion}` : ''} ·
					{t('deviceList.lastReport')}
					<time
						datetime={device.reportedAt}
						title={new Date(device.reportedAt).toLocaleString(dateLocale())}
						>{since(new Date(device.reportedAt))}</time
					>
				</small>
				<span class="dev-safe">
					<strong>{number(device.confirmed)}</strong>
					{t('deviceList.filesConfirmedByTheServer')}
					{#if device.files > device.confirmed}
						<span class="dev-of">
							{t('deviceList.of')}
							{number(device.files)}
							{t('deviceList.theDeviceSent')}</span
						>
					{/if}
				</span>
				<Bar
					pct={pct(device)}
					progress
					label={t('deviceList.numberOfNumber2OnThe', {
						number: number(device.verified),
						number2: number(total(device))
					})}
				/>
				<small class="dev-counts">
					{t('deviceList.waiting')}
					{number(device.pending + device.working)} · {t('deviceList.notSent')}
					{number(device.failed)}
					{#if device.trashed}
						· {t('deviceList.inTheTrash')} {number(device.trashed)}{/if}
					{#if device.gone}
						· {t('deviceList.noLongerOnTheServer')} {number(device.gone)}{/if}
				</small>
				{#if device.quiet}
					<p class="dev-warn">
						{t('deviceList.theDeviceHasNotReported')}
					</p>
				{/if}
				{#if missing[device.id]}
					{@const m = missing[device.id]}
					<div class="imp-report">
						{#if m.failures.length === 0 && m.gone.length === 0}
							<p>{t('deviceList.nothingIsMissing')}</p>
						{:else}
							<ul>
								{#each m.failures as failure, n (n)}
									<li><b class="mono">{failure.name}</b> {failure.reason}</li>
								{/each}
								{#each m.gone as gone (gone.checksum)}
									<li>
										<b class="mono">{gone.name || gone.checksum.slice(0, 12)}</b>
										{gone.inTrash
											? t('deviceList.isInTheTrashOn')
											: t('deviceList.wasDeletedFromTheServer')}
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
							>{missing[device.id] ? t('common.hide') : t('deviceList.whatIsMissing')}</Button
						>
					{/if}
					<Button small variant="danger" onclick={() => remove(device)}
						>{t('common.remove2')}</Button
					>
				</span>
			{/if}
		</li>
	{/each}
</ul>
