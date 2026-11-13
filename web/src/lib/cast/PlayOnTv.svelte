<script lang="ts">
	import Icon from '#lib/design/components/Icon.svelte';
	import { escapeLayer } from '#lib/design/layers.ts';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import { browserCaps, tvChoices, type TvChoice, type TvTarget } from './cast.ts';
	import { casting, follow, startAirPlay, startChromecast, stopCasting } from './session.svelte.ts';

	/** Sends what is on the screen to a TV, and keeps the TV on the photo that is shown. */
	let {
		id,
		kind,
		video
	}: {
		id: string;
		kind: 'photo' | 'video';
		/** The playing video, for AirPlay from Safari. */
		video?: () => HTMLVideoElement | null | undefined;
	} = $props();

	let open = $state(false);
	let busy = $state(false);

	// While the menu is open it is on top: Esc closes it, not the viewer under it.
	$effect(() => {
		if (open) return escapeLayer(() => (open = false));
	});
	const choices = $derived<TvChoice[]>(tvChoices(browserCaps(kind)));
	const names: Record<TvTarget, string> = {
		chromecast: 'Chromecast',
		airplay: 'AirPlay',
		dlna: 'DLNA'
	};

	// The TV follows the photo on the screen.
	$effect(() => {
		const current = id;
		if (casting()) follow(current).catch(() => showToast('err', t('cast.notOnTv')));
	});

	async function choose(choice: TvChoice) {
		if (!choice.available) return;
		open = false;
		busy = true;
		try {
			if (choice.target === 'chromecast') await startChromecast(id);
			else if (choice.target === 'airplay') {
				const element = video?.();
				if (element) await startAirPlay(element, id);
			}
		} catch (cause) {
			// Closing Chrome's picker without choosing is not a failure.
			if (!(cause && String(cause).includes('cancel'))) showToast('err', t('cast.failed'));
			await stopCasting().catch(() => undefined);
		} finally {
			busy = false;
		}
	}
</script>

<div class="share-wrap">
	<button
		type="button"
		class="icon-btn"
		class:viewer-on={!!casting()}
		aria-label={t('cast.playOnTv')}
		title={t('cast.playOnTv')}
		aria-expanded={open}
		disabled={busy}
		onclick={() => (open = !open)}><Icon name="tv" /></button
	>
	{#if open}
		<div class="share-menu tv-menu" role="menu" aria-label={t('cast.playOnTv')}>
			{#if casting()}
				<p class="tv-now">{t('cast.playingOn', { device: casting()?.device ?? '' })}</p>
				<button
					type="button"
					role="menuitem"
					onclick={() => {
						open = false;
						void stopCasting();
					}}><b>{t('cast.stop')}</b></button
				>
			{/if}
			{#each choices as choice (choice.target)}
				<button
					type="button"
					role="menuitem"
					aria-disabled={!choice.available}
					class:tv-off={!choice.available}
					onclick={() => choose(choice)}
				>
					<b>{names[choice.target]}</b>
					<small>{t(choice.note)}</small>
				</button>
			{/each}
		</div>
	{/if}
</div>
