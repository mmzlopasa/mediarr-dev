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
	import { tr } from '#lib/i18n.svelte.ts';
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
					? tr('Previše pokušaja. Pokušajte kasnije.', 'Too many attempts. Try again later.')
					: cause instanceof ApiError && cause.status === 401
						? tr('Pogrešan PIN.', 'Wrong PIN.')
						: tr(
								'PIN mora imati od 4 do 12 znamenki.',
								'The PIN must have between 4 and 12 digits.'
							);
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
			showToast('ok', tr(`Vraćeno u Fotke: ${changed}`, `Back in Photos: ${changed}`));
			clear();
			await view?.reload();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function purge() {
		if (!toPurge) return;
		try {
			const { changed } = await api.bulk(toPurge.ids, 'purge');
			showToast('ok', tr(`Trajno obrisano: ${changed}`, `Permanently deleted: ${changed}`));
			toPurge.clear();
			confirmPurge = false;
			await view?.reload();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr(item.hr, item.en)} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr(item.hr, item.en)}</h1>
		<p>
			{tr(
				'Skriveno od svih drugih prikaza i dijeljenja. Datoteke na serveru nisu šifrirane.',
				'Hidden from every other view and from sharing. The files on the server are not encrypted.'
			)}
		</p>
	</div>
	{#if status?.unlocked}
		<div class="ph-a">
			<Button small onclick={lock}><Icon name="lock" size={14} /> {tr('Zaključaj', 'Lock')}</Button>
		</div>
	{/if}
</div>

{#if failed}
	<Alert kind="err">{tr('Trezor se nije učitao.', 'The vault could not be loaded.')}</Alert>
{:else if !status}
	<Skeleton height="200px" />
{:else if status.unlocked}
	<CollectionView bind:this={view} scope="vault" {item}>
		{#snippet selectionActions(ids, clear)}
			<button
				type="button"
				class="icon-btn"
				aria-label={tr('Vrati u Fotke', 'Back to Photos')}
				title={tr('Vrati u Fotke', 'Back to Photos')}
				onclick={() => moveOut(ids, clear)}><Icon name="photo" /></button
			>
			<button
				type="button"
				class="icon-btn"
				aria-label={tr('Obriši trajno', 'Delete permanently')}
				title={tr('Obriši trajno', 'Delete permanently')}
				onclick={() => {
					toPurge = { ids, clear };
					confirmPurge = true;
				}}><Icon name="trash" /></button
			>
		{/snippet}
	</CollectionView>
{:else}
	<div class="org-box">
		<Card
			title={status.hasPin
				? tr('Otključaj trezor', 'Unlock the vault')
				: tr('Postavi PIN trezora', 'Set a vault PIN')}
		>
			<form class="form" onsubmit={submit}>
				{#if formError}<Alert kind="err">{formError}</Alert>{/if}
				<Input
					label="PIN"
					type="password"
					inputmode="numeric"
					autocomplete="off"
					hint={status.hasPin
						? undefined
						: tr(
								'Od 4 do 12 znamenki. Izgubljeni PIN može resetirati samo administrator servera.',
								'From 4 to 12 digits. Only the server administrator can reset a lost PIN.'
							)}
					bind:value={pin}
				/>
				<Button type="submit" variant="gold" disabled={busy || !pin}
					>{status.hasPin ? tr('Otključaj', 'Unlock') : tr('Postavi PIN', 'Set PIN')}</Button
				>
			</form>
		</Card>
	</div>
{/if}

<Dialog title={tr('Obrisati trajno?', 'Delete permanently?')} bind:open={confirmPurge}>
	<p>
		{tr(
			'Originali se brišu s diska. To se ne može poništiti.',
			'The originals are removed from the disk. This cannot be undone.'
		)}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirmPurge = false)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" onclick={purge}>{tr('Obriši trajno', 'Delete permanently')}</Button>
	{/snippet}
</Dialog>
