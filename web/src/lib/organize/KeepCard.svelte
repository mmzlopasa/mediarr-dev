<script lang="ts">
	import { onMount } from 'svelte';
	import QRCode from 'qrcode';
	import {
		api,
		formatBytes,
		type BackupDestination,
		type KeepGuest,
		type KeepInvite
	} from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, t, k, type Key } from '#lib/i18n.svelte.ts';

	/**
	 * Copies of the backup at other Mediarr servers, and the backups this server keeps for others.
	 * Both are encrypted by the server they belong to; the one that keeps them cannot read them.
	 */
	let { onChange }: { onChange?: () => void } = $props();

	const GB = 1024 ** 3;
	let destinations = $state<BackupDestination[] | undefined>();
	let guests = $state<KeepGuest[] | undefined>();
	let code = $state('');
	let pairing = $state(false);
	let name = $state('');
	let sizeGb = $state('100');
	let address = $state('');
	let invite = $state<KeepInvite | undefined>();
	let qr = $state('');
	let removing = $state<string | undefined>();
	let confirmName = $state('');
	let resizing = $state<string | undefined>();
	let resizeGb = $state('');

	async function load() {
		[destinations, guests] = await Promise.all([
			api.backupDestinations().catch(() => destinations ?? []),
			api.keepGuests().catch(() => guests ?? [])
		]);
		// A code that has been used, or whose guest is gone, is no longer worth showing.
		const shown = guests.find((guest) => guest.id === invite?.guest.id);
		if (invite && (!shown || !shown.inviteExpiresAt)) invite = undefined;
	}

	onMount(() => {
		address = window.location.origin;
		load();
	});

	function fail(cause: unknown) {
		showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
	}

	async function act(work: () => Promise<unknown>, done?: string) {
		try {
			await work();
			if (done) showToast('ok', done);
		} catch (cause) {
			fail(cause);
		}
		await load();
		onChange?.();
	}

	/** A key sent over plain HTTP can be read on the way, unless the address is in the home network. */
	function exposed(value: string) {
		try {
			const url = new URL(value);
			if (url.protocol === 'https:') return false;
			const host = url.hostname;
			return !(
				host === 'localhost' ||
				host.endsWith('.local') ||
				/^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.)/.test(
					host
				)
			);
		} catch {
			return false;
		}
	}

	async function pair(event: SubmitEvent) {
		event.preventDefault();
		pairing = true;
		await act(async () => {
			await api.addBackupDestination(code);
			code = '';
		}, t('keepCard.pairedTheNextBackupGoes'));
		pairing = false;
	}

	async function show(next: KeepInvite) {
		invite = next;
		qr = await QRCode.toString(next.code, { type: 'svg', margin: 1, errorCorrectionLevel: 'M' });
	}

	async function inviteGuest(event: SubmitEvent) {
		event.preventDefault();
		await act(async () => {
			await show(
				await api.inviteKeepGuest({
					name,
					quotaBytes: Math.round(Number(sizeGb) * GB),
					address
				})
			);
			name = '';
		});
	}

	async function copyCode() {
		if (!invite) return;
		await navigator.clipboard.writeText(invite.code);
		showToast('ok', t('keepCard.theCodeIsCopied'));
	}

	const when = (value?: string) =>
		value
			? new Date(value).toLocaleString(lang(), { dateStyle: 'medium', timeStyle: 'short' })
			: t('keepCard.notYet');
	const GUEST_STATUS: Record<KeepGuest['status'], { label: Key; tone: string }> = {
		invited: { label: k('keepCard.invited'), tone: '' },
		active: { label: k('keepCard.active'), tone: 'ok' },
		stopped: { label: k('keepCard.stopped'), tone: 'err' }
	};
</script>

<Card id="keep" title={t('keepCard.aCopyAtARelative')}>
	<p class="alb-meta">
		{t('keepCard.twoMediarrServersKeepAn')}
	</p>

	<div class="set-group">
		<h3>{t('keepCard.myCopyAtOthers')}</h3>
		{#if destinations === undefined}
			<Skeleton height="48px" />
		{:else}
			{#if destinations.length}
				<ul class="set-list" aria-label={t('keepCard.myCopyAtOthers')}>
					{#each destinations as destination (destination.id)}
						<li data-destination={destination.name}>
							<span class="set-list-t">
								<b>{destination.name}</b>
								<small>
									<span class="mono">{destination.address}</span> ·
									{t('keepCard.lastBackup')}
									{when(destination.lastSuccessAt)} ·
									{t('keepCard.upTo')}
									{formatBytes(destination.quotaBytes)}
									{#if exposed(destination.address)}
										· <em class="set-chip err">{t('keepCard.noHttps')}</em>
									{/if}
								</small>
								{#if destination.lastError}
									<small class="keep-err">{destination.lastError}</small>
								{/if}
							</span>
							<span class="imp-acts">
								<Button
									small
									onclick={() =>
										act(
											() => api.startBackupRun('restore_test', destination.id),
											t('keepCard.theRestoreTestHasStarted')
										)}>{t('keepCard.testBringingItBack')}</Button
								>
								<Button
									small
									variant="danger"
									onclick={() => act(() => api.removeBackupDestination(destination.id))}
									>{t('common.remove')}</Button
								>
							</span>
						</li>
					{/each}
				</ul>
			{/if}
			<form class="form" onsubmit={pair}>
				<label class="keep-code">
					<span>{t('keepCard.codeFromTheOtherMediarr')}</span>
					<textarea
						class="in mono"
						rows="3"
						bind:value={code}
						placeholder="mediarr-keep:…"
						required
						spellcheck="false"></textarea>
				</label>
				<div class="set-foot">
					<Button type="submit" variant="gold" small disabled={pairing}
						>{pairing ? t('keepCard.pairing') : t('keepCard.pair')}</Button
					>
				</div>
			</form>
		{/if}
	</div>

	<div class="set-group">
		<h3>{t('keepCard.iKeepForOthers')}</h3>
		{#if guests === undefined}
			<Skeleton height="48px" />
		{:else}
			{#if guests.length}
				<ul class="set-list" aria-label={t('keepCard.iKeepForOthers')}>
					{#each guests as guest (guest.id)}
						<li data-guest={guest.status}>
							<span class="set-list-t">
								<b>{guest.name}</b>
								<small>
									<em class="set-chip {GUEST_STATUS[guest.status].tone}"
										>{t(GUEST_STATUS[guest.status].label)}</em
									>
									{formatBytes(guest.usedBytes)} / {formatBytes(guest.quotaBytes)} ·
									{t('keepCard.lastBackup')}
									{when(guest.lastBackupAt)}
									{#if guest.deletedBytes > 0}
										· {t('keepCard.deletedKept')}: {formatBytes(guest.deletedBytes)}
									{/if}
								</small>
								<Bar pct={(guest.usedBytes / guest.quotaBytes) * 100} />
								{#if resizing === guest.id}
									<form
										class="keep-inline"
										onsubmit={(event) => {
											event.preventDefault();
											act(() =>
												api.updateKeepGuest(guest.id, {
													quotaBytes: Math.round(Number(resizeGb) * GB),
													status: guest.status === 'stopped' ? 'stopped' : 'active'
												})
											);
											resizing = undefined;
										}}
									>
										<Input label="GB" type="number" min="1" bind:value={resizeGb} />
										<Button type="submit" small variant="gold">{t('common.save')}</Button>
									</form>
								{/if}
								{#if removing === guest.id}
									<form
										class="keep-inline"
										onsubmit={(event) => {
											event.preventDefault();
											act(() => api.removeKeepGuest(guest.id, confirmName));
											removing = undefined;
											confirmName = '';
										}}
									>
										<Input
											label={t('keepCard.typeNameToDeleteThe', { name: guest.name })}
											bind:value={confirmName}
										/>
										<Button
											type="submit"
											small
											variant="danger"
											disabled={confirmName !== guest.name}>{t('keepCard.deleteTheCopy')}</Button
										>
									</form>
								{/if}
							</span>
							<span class="imp-acts">
								<Button small onclick={async () => show(await api.reinviteKeepGuest(guest.id))}
									>{t('keepCard.newCode')}</Button
								>
								{#if guest.status !== 'invited'}
									<Button
										small
										onclick={() =>
											act(() =>
												api.updateKeepGuest(guest.id, {
													quotaBytes: guest.quotaBytes,
													status: guest.status === 'stopped' ? 'active' : 'stopped'
												})
											)}
										>{guest.status === 'stopped' ? t('common.resume') : t('common.stop')}</Button
									>
								{/if}
								<Button
									small
									onclick={() => {
										resizing = resizing === guest.id ? undefined : guest.id;
										resizeGb = String(Math.round(guest.quotaBytes / GB));
									}}>{t('keepCard.size')}</Button
								>
								{#if guest.deletedBytes > 0}
									<Button
										small
										onclick={() =>
											act(async () => {
												const { restored } = await api.restoreKeepDeleted(guest.id);
												showToast('ok', t('keepCard.filesBroughtBackRestored', { restored }));
											})}>{t('keepCard.bringBackWhatWasDeleted')}</Button
									>
								{/if}
								<Button
									small
									variant="danger"
									onclick={() => {
										removing = removing === guest.id ? undefined : guest.id;
										confirmName = '';
									}}>{t('common.remove')}</Button
								>
							</span>
						</li>
					{/each}
				</ul>
			{/if}

			{#if invite}
				<div class="keep-invite" data-testid="keep-invite">
					<!-- eslint-disable-next-line svelte/no-at-html-tags -- an SVG drawn by the QR library from the code -->
					<div class="keep-qr" aria-hidden="true">{@html qr}</div>
					<div class="keep-invite-t">
						<b>{t('keepCard.codeForName', { name: invite.guest.name })}</b>
						<p class="alb-meta">
							{t('keepCard.sendItToTheAdministrator')}
							{when(invite.expiresAt)}.
						</p>
						<code class="keep-codebox">{invite.code}</code>
						<div class="set-foot">
							<Button small onclick={copyCode}>{t('keepCard.copy')}</Button>
							<Button small onclick={() => (invite = undefined)}>{t('keepCard.done')}</Button>
						</div>
					</div>
				</div>
			{/if}

			<form class="form" onsubmit={inviteGuest}>
				<Input label={t('keepCard.forWhom')} bind:value={name} required maxlength={100} />
				<Input label={t('keepCard.atMostGb')} type="number" min="1" bind:value={sizeGb} required />
				<Input label={t('keepCard.theAddressTheOtherServer')} bind:value={address} required />
				{#if exposed(address)}
					<Alert kind="warn">{t('keepCard.overPlainHttpTheKey')}</Alert>
				{/if}
				<div class="set-foot">
					<Button type="submit" variant="gold" small>{t('keepCard.invite')}</Button>
				</div>
			</form>
		{/if}
	</div>
</Card>
