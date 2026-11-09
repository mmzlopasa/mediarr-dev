<script lang="ts">
	import { onMount } from 'svelte';
	import { canShareFiles, prefersSmall, rememberSmall, shareAssets } from '#lib/share.ts';
	import Icon from './Icon.svelte';
	import { showToast } from './toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	/** Sends photos to another app, as originals or smaller for messages. Only where it can. */
	let { ids, onDone }: { ids: string[]; onDone?: () => void } = $props();

	let able = $state(false);
	let open = $state(false);
	let busy = $state(false);
	let small = $state(false);

	onMount(() => {
		able = canShareFiles();
		small = prefersSmall();
	});

	async function send(choice: boolean) {
		open = false;
		rememberSmall(choice);
		small = choice;
		busy = true;
		try {
			await shareAssets(ids, choice);
			onDone?.();
		} catch (cause) {
			// Closing the sheet without sending is not a failure.
			if (!(cause instanceof DOMException && cause.name === 'AbortError')) {
				showToast('err', t('shareButton.sendingDidNotWork'));
			}
		} finally {
			busy = false;
		}
	}
</script>

{#if able}
	<div class="share-wrap">
		<button
			type="button"
			class="icon-btn"
			aria-label={t('shareButton.share')}
			title={t('shareButton.share')}
			aria-expanded={open}
			disabled={busy}
			onclick={() => (open = !open)}><Icon name="share" /></button
		>
		{#if open}
			<div class="share-menu" role="menu">
				<button type="button" role="menuitem" class:on={!small} onclick={() => send(false)}>
					<b>{t('shareButton.original')}</b>
					<small>{t('shareButton.asItIs')}</small>
				</button>
				<button type="button" role="menuitem" class:on={small} onclick={() => send(true)}>
					<b>{t('shareButton.smallerForMessages')}</b>
					<small>{t('shareButton.aJpegWithoutLocation')}</small>
				</button>
			</div>
		{/if}
	</div>
{/if}
