<script lang="ts">
	import QRCode from 'qrcode';
	import { api, type QRSignIn, type QRSignInState } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import { left, onlyHere, withServer } from './qr.ts';

	/**
	 * Shows a one-time code that a phone scans to sign in to this account. The phone is signed in
	 * only after this screen allows it, so a photo of the code is not enough.
	 */
	let { open = $bindable(false) }: { open?: boolean } = $props();

	let code = $state<QRSignIn>();
	let current = $state<QRSignInState>();
	let problem = $state('');
	let svg = $state('');
	let now = $state(Date.now());
	let reachable = $state('');
	let answering = $state(false);

	const local = $derived(onlyHere(code?.server));
	const status = $derived(
		current?.status ?? (code && Date.parse(code.expiresAt) < now ? 'expired' : 'waiting')
	);
	const link = $derived(
		code && local && reachable.trim() ? safeLink(code.link, reachable) : code?.link
	);

	function safeLink(base: string, server: string): string {
		try {
			new URL(server.trim());
			return withServer(base, server);
		} catch {
			return base;
		}
	}

	async function fresh() {
		problem = '';
		current = undefined;
		code = undefined;
		svg = '';
		try {
			code = await api.createQRSignIn();
		} catch (error) {
			problem = error instanceof Error ? error.message : String(error);
		}
	}

	async function answer(allow: boolean) {
		if (!code) return;
		answering = true;
		try {
			await api.answerQRSignIn(code.id, allow);
			current = await api.qrSignIn(code.id);
		} catch (error) {
			problem = error instanceof Error ? error.message : String(error);
		} finally {
			answering = false;
		}
	}

	$effect(() => {
		if (open) void fresh();
	});

	$effect(() => {
		if (!link) return;
		void QRCode.toString(link, { type: 'svg', margin: 1, errorCorrectionLevel: 'M' }).then(
			(value) => (svg = value)
		);
	});

	// While the dialog is open, the clock ticks and the server is asked whether a phone has scanned.
	$effect(() => {
		if (!open || !code) return;
		const id = code.id;
		const timer = setInterval(async () => {
			now = Date.now();
			if (status === 'requested' || status === 'expired' || status === 'denied') return;
			if (status === 'used') return;
			try {
				current = await api.qrSignIn(id);
			} catch {
				// A missed answer is asked again on the next tick.
			}
		}, 1500);
		return () => clearInterval(timer);
	});
</script>

<Dialog title={t('qRSignInDialog.signInOnAPhone')} bind:open>
	<div class="qrs" aria-live="polite">
		{#if problem}
			<p class="form-err" role="alert">{problem}</p>
		{/if}
		{#if !code && !problem}
			<div class="qrs-code qrs-wait" aria-busy="true"></div>
		{:else if code && (status === 'waiting' || status === 'requested')}
			{#if status === 'waiting'}
				<p class="qrs-lead">
					{t('qRSignInDialog.inTheMediarrAppTap')}
				</p>
				<div class="qrs-code" role="img" aria-label={t('qRSignInDialog.signInQrCode')}>
					<!-- eslint-disable-next-line svelte/no-at-html-tags -- an SVG drawn here from our own link -->
					{@html svg}
				</div>
				<p class="qrs-typed">
					{t('qRSignInDialog.orTypeTheCode')}
					<b data-testid="qr-code">{code.code}</b>
					<span class="qrs-left">{t('qRSignInDialog.validFor')} {left(code.expiresAt, now)}</span>
				</p>
				{#if local}
					<label class="qrs-addr">
						<span>{t('qRSignInDialog.thisBrowserReachesTheServer')}</span>
						<input class="in" placeholder="http://192.168.1.20:9851" bind:value={reachable} />
					</label>
				{/if}
			{:else}
				<div class="qrs-ask" role="alertdialog" aria-labelledby="qrs-ask-t">
					<b id="qrs-ask-t"
						>{t('qRSignInDialog.allowSignInOnValue', { value: current?.device ?? '' })}</b
					>
					<p>
						{t('qRSignInDialog.allowOnlyIfYouJust')}
					</p>
					<div class="qrs-btns">
						<Button disabled={answering} onclick={() => answer(false)}
							>{t('qRSignInDialog.deny')}</Button
						>
						<Button variant="gold" disabled={answering} onclick={() => answer(true)}
							>{t('qRSignInDialog.allow')}</Button
						>
					</div>
				</div>
			{/if}
		{:else if status === 'allowed' || status === 'used'}
			<p class="qrs-done">
				{current?.device
					? t('qRSignInDialog.valueIsSignedInIt', {
							value: current.device,
							value2: current.device
						})
					: t('qRSignInDialog.theDeviceIsSignedIn')}
			</p>
			<div class="qrs-btns">
				<Button onclick={() => (open = false)}>{t('qRSignInDialog.done')}</Button>
			</div>
		{:else if code}
			<p class="qrs-lead">
				{status === 'denied'
					? t('qRSignInDialog.theSignInWasDenied')
					: t('qRSignInDialog.theCodeHasExpired')}
			</p>
			<div class="qrs-btns">
				<Button onclick={fresh}>{t('qRSignInDialog.newCode')}</Button>
			</div>
		{/if}
	</div>
</Dialog>
