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
	import { lang, tr } from '#lib/i18n.svelte.ts';

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
		showToast(
			'err',
			cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
		);
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
		await act(
			async () => {
				await api.addBackupDestination(code);
				code = '';
			},
			tr('Upareno. Sljedeći backup ide i tamo.', 'Paired. The next backup goes there too.')
		);
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
		showToast('ok', tr('Kod je kopiran.', 'The code is copied.'));
	}

	const when = (value?: string) =>
		value
			? new Date(value).toLocaleString(lang(), { dateStyle: 'medium', timeStyle: 'short' })
			: tr('još nije', 'not yet');
	const GUEST_STATUS: Record<KeepGuest['status'], { hr: string; en: string; tone: string }> = {
		invited: { hr: 'Pozvan', en: 'Invited', tone: '' },
		active: { hr: 'Aktivan', en: 'Active', tone: 'ok' },
		stopped: { hr: 'Zaustavljen', en: 'Stopped', tone: 'err' }
	};
</script>

<Card id="keep" title={tr('Kopija kod rođaka', 'A copy at a relative’s')}>
	<p class="alb-meta">
		{tr(
			'Dva Mediarra čuvaju šifriranu kopiju jedan drugoga. Onaj tko čuva ne može je pročitati, a što se obriše, čuva još 90 dana.',
			'Two Mediarr servers keep an encrypted copy of each other. The one that keeps it cannot read it, and what is deleted from it is kept for 90 more days.'
		)}
	</p>

	<div class="set-group">
		<h3>{tr('Moja kopija kod drugih', 'My copy at others')}</h3>
		{#if destinations === undefined}
			<Skeleton height="48px" />
		{:else}
			{#if destinations.length}
				<ul class="set-list" aria-label={tr('Moja kopija kod drugih', 'My copy at others')}>
					{#each destinations as destination (destination.id)}
						<li data-destination={destination.name}>
							<span class="set-list-t">
								<b>{destination.name}</b>
								<small>
									<span class="mono">{destination.address}</span> ·
									{tr('zadnji backup', 'last backup')}
									{when(destination.lastSuccessAt)} ·
									{tr('do', 'up to')}
									{formatBytes(destination.quotaBytes)}
									{#if exposed(destination.address)}
										· <em class="set-chip err">{tr('bez HTTPS-a', 'no HTTPS')}</em>
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
											tr('Test vraćanja je pokrenut.', 'The restore test has started.')
										)}>{tr('Testiraj vraćanje', 'Test bringing it back')}</Button
								>
								<Button
									small
									variant="danger"
									onclick={() => act(() => api.removeBackupDestination(destination.id))}
									>{tr('Ukloni', 'Remove')}</Button
								>
							</span>
						</li>
					{/each}
				</ul>
			{/if}
			<form class="form" onsubmit={pair}>
				<label class="keep-code">
					<span>{tr('Kod od drugog Mediarra', 'Code from the other Mediarr')}</span>
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
						>{pairing ? tr('Uparujem…', 'Pairing…') : tr('Upari', 'Pair')}</Button
					>
				</div>
			</form>
		{/if}
	</div>

	<div class="set-group">
		<h3>{tr('Čuvam za druge', 'I keep for others')}</h3>
		{#if guests === undefined}
			<Skeleton height="48px" />
		{:else}
			{#if guests.length}
				<ul class="set-list" aria-label={tr('Čuvam za druge', 'I keep for others')}>
					{#each guests as guest (guest.id)}
						<li data-guest={guest.status}>
							<span class="set-list-t">
								<b>{guest.name}</b>
								<small>
									<em class="set-chip {GUEST_STATUS[guest.status].tone}"
										>{tr(GUEST_STATUS[guest.status].hr, GUEST_STATUS[guest.status].en)}</em
									>
									{formatBytes(guest.usedBytes)} / {formatBytes(guest.quotaBytes)} ·
									{tr('zadnji backup', 'last backup')}
									{when(guest.lastBackupAt)}
									{#if guest.deletedBytes > 0}
										· {tr('obrisano se čuva', 'deleted, kept')}: {formatBytes(guest.deletedBytes)}
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
										<Button type="submit" small variant="gold">{tr('Spremi', 'Save')}</Button>
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
											label={tr(
												`Upišite „${guest.name}“ za brisanje kopije`,
												`Type “${guest.name}” to delete the copy`
											)}
											bind:value={confirmName}
										/>
										<Button
											type="submit"
											small
											variant="danger"
											disabled={confirmName !== guest.name}
											>{tr('Obriši kopiju', 'Delete the copy')}</Button
										>
									</form>
								{/if}
							</span>
							<span class="imp-acts">
								<Button small onclick={async () => show(await api.reinviteKeepGuest(guest.id))}
									>{tr('Novi kod', 'New code')}</Button
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
										>{guest.status === 'stopped'
											? tr('Nastavi', 'Resume')
											: tr('Zaustavi', 'Stop')}</Button
									>
								{/if}
								<Button
									small
									onclick={() => {
										resizing = resizing === guest.id ? undefined : guest.id;
										resizeGb = String(Math.round(guest.quotaBytes / GB));
									}}>{tr('Veličina', 'Size')}</Button
								>
								{#if guest.deletedBytes > 0}
									<Button
										small
										onclick={() =>
											act(async () => {
												const { restored } = await api.restoreKeepDeleted(guest.id);
												showToast(
													'ok',
													tr(`Vraćeno datoteka: ${restored}.`, `Files brought back: ${restored}.`)
												);
											})}>{tr('Vrati obrisano', 'Bring back what was deleted')}</Button
									>
								{/if}
								<Button
									small
									variant="danger"
									onclick={() => {
										removing = removing === guest.id ? undefined : guest.id;
										confirmName = '';
									}}>{tr('Ukloni', 'Remove')}</Button
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
						<b>{tr(`Kod za ${invite.guest.name}`, `Code for ${invite.guest.name}`)}</b>
						<p class="alb-meta">
							{tr(
								'Pošaljite ga adminu drugog servera: u Backup → Kopija kod rođaka ga zalijepi ili skenira. Vrijedi jednom, do',
								'Send it to the administrator of the other server, who pastes or scans it under Backup → A copy at a relative’s. It works once, until'
							)}
							{when(invite.expiresAt)}.
						</p>
						<code class="keep-codebox">{invite.code}</code>
						<div class="set-foot">
							<Button small onclick={copyCode}>{tr('Kopiraj', 'Copy')}</Button>
							<Button small onclick={() => (invite = undefined)}>{tr('Gotovo', 'Done')}</Button>
						</div>
					</div>
				</div>
			{/if}

			<form class="form" onsubmit={inviteGuest}>
				<Input label={tr('Za koga', 'For whom')} bind:value={name} required maxlength={100} />
				<Input
					label={tr('Najviše (GB)', 'At most (GB)')}
					type="number"
					min="1"
					bind:value={sizeGb}
					required
				/>
				<Input
					label={tr(
						'Adresa na kojoj vas drugi server vidi',
						'The address the other server reaches you at'
					)}
					bind:value={address}
					required
				/>
				{#if exposed(address)}
					<Alert kind="warn"
						>{tr(
							'Preko običnog HTTP-a ključ se može presresti. Sadržaj je i dalje šifriran, ali koristite HTTPS ili VPN (npr. Tailscale).',
							'Over plain HTTP the key can be read on the way. The contents stay encrypted, but use HTTPS or a VPN (such as Tailscale).'
						)}</Alert
					>
				{/if}
				<div class="set-foot">
					<Button type="submit" variant="gold" small>{tr('Pozovi', 'Invite')}</Button>
				</div>
			</form>
		{/if}
	</div>
</Card>
