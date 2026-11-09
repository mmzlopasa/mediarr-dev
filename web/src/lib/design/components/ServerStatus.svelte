<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type ServerStatus } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	const CHECK_EVERY_MS = 60000;
	const DISMISSED_KEY = 'mediarr_update_seen';

	let status = $state<ServerStatus>();
	let online = $state(true);
	let dialogOpen = $state(false);

	const percent = $derived(
		status && status.diskTotalBytes > 0
			? Math.min(100, (status.diskUsedBytes / status.diskTotalBytes) * 100)
			: 0
	);

	async function check() {
		try {
			status = await api.serverStatus();
			online = true;
			const latest = status.latestVersion;
			if (status.updateAvailable && latest && localStorage.getItem(DISMISSED_KEY) !== latest) {
				dialogOpen = true;
			}
		} catch {
			online = false;
		}
	}

	function dismiss() {
		if (status?.latestVersion) localStorage.setItem(DISMISSED_KEY, status.latestVersion);
		dialogOpen = false;
	}

	onMount(() => {
		check();
		const timer = setInterval(check, CHECK_EVERY_MS);
		return () => clearInterval(timer);
	});
</script>

<div class="srv">
	{#if status}
		<div class="srv-card">
			<b>{t('serverStatus.storage')}</b>
			<small>
				{t('serverStatus.formatbytesOfFormatbytes2Used', {
					formatBytes: formatBytes(status.diskUsedBytes),
					formatBytes2: formatBytes(status.diskTotalBytes)
				})}
			</small>
			<span class="srv-bar"><span style="width:{percent}%"></span></span>
		</div>
	{/if}
	<div class="srv-line">
		<span class="srv-dot" class:off={!online}></span>
		<span>{online ? t('serverStatus.serverOnline') : t('serverStatus.serverOffline')}</span>
		{#if status}<span class="srv-v">{status.version}</span>{/if}
	</div>
	{#if status?.updateAvailable}
		<button type="button" class="srv-new" onclick={() => (dialogOpen = true)}>
			{t('serverStatus.versionLatestversionIsAvailable', { latestVersion: status.latestVersion })}
		</button>
	{/if}
</div>

<Dialog title={t('serverStatus.aNewVersionIsAvailable')} bind:open={dialogOpen}>
	<p>
		{t('serverStatus.mediarrLatestversionIsAvailableThis', {
			latestVersion: status?.latestVersion,
			version: status?.version
		})}
	</p>
	<p>
		{t('serverStatus.theServerAdministratorUpdatesIt')}
	</p>
	<pre class="srv-cmd">docker compose pull && docker compose up -d</pre>
	{#snippet footer()}
		<Button variant="gold" small onclick={dismiss}>{t('serverStatus.ok')}</Button>
	{/snippet}
</Dialog>
