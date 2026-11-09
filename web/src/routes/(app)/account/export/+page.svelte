<script lang="ts">
	import { onMount } from 'svelte';
	import { api, ApiError, type LibraryExport } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import ExportList from '#lib/organize/ExportList.svelte';
	import { exportBusy } from '#lib/organize/exports.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let exports = $state<LibraryExport[] | undefined>();
	let starting = $state(false);
	let timer: ReturnType<typeof setTimeout> | undefined;

	async function load() {
		exports = await api.myExports().catch(() => exports ?? []);
		clearTimeout(timer);
		// Progress is asked for only while something runs.
		if (exportBusy(exports)) timer = setTimeout(load, 3000);
	}

	onMount(() => {
		load();
		return () => clearTimeout(timer);
	});

	async function start() {
		starting = true;
		try {
			await api.startExport();
			showToast('ok', t('export.started'));
		} catch (cause) {
			showToast('err', exportError(cause));
		} finally {
			starting = false;
		}
		load();
	}

	function exportError(cause: unknown) {
		if (cause instanceof ApiError && cause.status === 507) return t('export.noSpace');
		if (cause instanceof ApiError && cause.status === 409) return t('export.alreadyRunning');
		return (cause as Error).message;
	}

	const running = $derived(exports?.some((entry) => entry.status === 'running') ?? false);
</script>

<svelte:head><title>{t('export.title')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t('export.title')}</h1>
		<p>{t('export.intro')}</p>
	</div>
</div>

<div class="imp">
	<Card id="new" title={t('export.newExport')}>
		<p class="alb-meta">{t('export.whatIsIn')}</p>
		<p class="alb-meta">{t('export.howLong')}</p>
		<div class="set-foot">
			<Button
				variant="gold"
				small
				disabled={starting || running || exports === undefined}
				onclick={start}>{t('export.start')}</Button
			>
		</div>
	</Card>

	<Card id="exports" title={t('export.yours')}>
		<ExportList entries={exports} label={t('export.yours')} onchange={load} />
	</Card>
</div>
