<script lang="ts">
	import { onMount } from 'svelte';
	import { api, ApiError, type VaultStatus } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import CollectionView from '#lib/organize/CollectionView.svelte';

	const CHECK_MS = 30000;
	const item = appNav.find((candidate) => candidate.path === '/vault') ?? appNav[0];

	let status = $state<VaultStatus>();
	let failed = $state(false);
	let pin = $state('');
	let formError = $state('');
	let busy = $state(false);
	let view = $state<CollectionView>();
	let toPurge = $state<{ ids: string[]; clear: () => void }>();
	let confirmPurge = $state(false);

	async function load() {
		try {
			status = await api.vaultStatus();
			failed = false;
		} catch {
			failed = true;
		}
	}

	// The vault locks itself after a while, and the page must then stop showing anything.
	onMount(() => {
		load();
		const timer = setInterval(load, CHECK_MS);
		return () => clearInterval(timer);
	});

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		formError = '';
		try {
			if (status?.hasPin) {
				await api.unlockVault(pin);
			} else {
				await api.setVaultPin(pin);
				await api.unlockVault(pin);
			}
			pin = '';
			await load();
		} catch (cause) {
			formError =
				cause instanceof ApiError && cause.status === 429
					? t('common.tooManyAttemptsTryAgain')
					: cause instanceof ApiError && cause.status === 401
						? t('vault.wrongPin')
						: t('vault.thePinMustHaveBetween');
		} finally {
			busy = false;
		}
	}

	async function lock() {
		await api.lockVault().catch(() => {});
		await load();
	}

	async function moveOut(ids: string[], clear: () => void) {
		try {
			const { changed } = await api.bulk(ids, 'unvault');
			showToast('ok', t('vault.backInMediaChanged', { changed }));
			clear();
			await view?.reload();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function purge() {
		if (!toPurge) return;
		try {
			const { changed } = await api.bulk(toPurge.ids, 'purge');
			showToast('ok', t('vault.permanentlyDeletedChanged', { changed }));
			toPurge.clear();
			confirmPurge = false;
			await view?.reload();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t(item.label)}</h1>
		<p>
			{t('vault.hiddenFromEveryOtherView')}
		</p>
	</div>
	{#if status?.unlocked}
		<div class="ph-a">
			<Button small onclick={lock}><Icon name="lock" size={14} /> {t('vault.lock')}</Button>
		</div>
	{/if}
</div>

{#if failed}
	<Alert kind="err">{t('vault.theVaultCouldNotBe')}</Alert>
{:else if !status}
	<Skeleton height="200px" />
{:else if status.unlocked}
	<CollectionView bind:this={view} scope="vault" {item}>
		{#snippet selectionActions(ids, clear)}
			<button
				type="button"
				class="icon-btn"
				aria-label={t('vault.backToMedia')}
				title={t('vault.backToMedia')}
				onclick={() => moveOut(ids, clear)}><Icon name="photo" /></button
			>
			<button
				type="button"
				class="icon-btn"
				aria-label={t('vault.deletePermanently')}
				title={t('vault.deletePermanently')}
				onclick={() => {
					toPurge = { ids, clear };
					confirmPurge = true;
				}}><Icon name="trash" /></button
			>
		{/snippet}
	</CollectionView>
{:else}
	<div class="org-box">
		<Card title={status.hasPin ? t('vault.unlockTheVault') : t('vault.setAVaultPin')}>
			<form class="form" onsubmit={submit}>
				{#if formError}<Alert kind="err">{formError}</Alert>{/if}
				<Input
					label={t('vault.pin')}
					type="password"
					inputmode="numeric"
					autocomplete="off"
					hint={status.hasPin ? undefined : t('vault.from4To12Digits')}
					bind:value={pin}
				/>
				<Button type="submit" variant="gold" disabled={busy || !pin}
					>{status.hasPin ? t('vault.unlock') : t('vault.setPin')}</Button
				>
			</form>
		</Card>
	</div>
{/if}

<Dialog title={t('vault.deletePermanently2')} bind:open={confirmPurge}>
	<p>
		{t('vault.theOriginalsAreRemovedFrom')}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmPurge = false)}>{t('common.cancel')}</Button>
		<Button variant="danger" onclick={purge}>{t('vault.deletePermanently')}</Button>
	{/snippet}
</Dialog>
