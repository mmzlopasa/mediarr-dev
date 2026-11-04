<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type ServerStatus } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

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
			<b>{tr('Prostor', 'Storage')}</b>
			<small>
				{tr(
					`${formatBytes(status.diskUsedBytes)} od ${formatBytes(status.diskTotalBytes)} zauzeto`,
					`${formatBytes(status.diskUsedBytes)} of ${formatBytes(status.diskTotalBytes)} used`
				)}
			</small>
			<span class="srv-bar"><span style="width:{percent}%"></span></span>
		</div>
	{/if}
	<div class="srv-line">
		<span class="srv-dot" class:off={!online}></span>
		<span
			>{online
				? tr('Server radi', 'Server online')
				: tr('Server ne odgovara', 'Server offline')}</span
		>
		{#if status}<span class="srv-v">{status.version}</span>{/if}
	</div>
	{#if status?.updateAvailable}
		<button type="button" class="srv-new" onclick={() => (dialogOpen = true)}>
			{tr(
				`Dostupna verzija ${status.latestVersion}`,
				`Version ${status.latestVersion} is available`
			)}
		</button>
	{/if}
</div>

<Dialog title={tr('Dostupna je nova verzija', 'A new version is available')} bind:open={dialogOpen}>
	<p>
		{tr(
			`Mediarr ${status?.latestVersion} je dostupan. Ovaj server koristi ${status?.version}.`,
			`Mediarr ${status?.latestVersion} is available. This server runs ${status?.version}.`
		)}
	</p>
	<p>
		{tr('Nadogradnju radi administrator servera:', 'The server administrator updates it with:')}
	</p>
	<pre class="srv-cmd">docker compose pull && docker compose up -d</pre>
	{#snippet footer()}
		<Button variant="gold" small onclick={dismiss}>{tr('U redu', 'OK')}</Button>
	{/snippet}
</Dialog>
