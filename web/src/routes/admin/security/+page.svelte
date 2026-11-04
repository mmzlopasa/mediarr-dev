<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type SecurityEvent, type SecuritySettings } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let settings = $state<SecuritySettings>();
	let events = $state<SecurityEvent[]>();
	let ipEnabled = $state(false);
	let ipList = $state('');
	let deviceApproval = $state(false);
	let saving = $state(false);

	function use(next: SecuritySettings) {
		settings = next;
		ipEnabled = next.ipAllowlistEnabled;
		ipList = next.ipAllowlist.join('\n');
		deviceApproval = next.deviceApprovalEnabled;
	}

	async function load() {
		try {
			use(await api.security());
			events = await api.securityEvents();
		} catch {
			showToast('err', tr('Podaci se ne mogu učitati.', 'This could not be loaded.'));
		}
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		saving = true;
		try {
			use(
				await api.setSecurity({
					ipAllowlistEnabled: ipEnabled,
					ipAllowlist: ipList.split('\n'),
					deviceApprovalEnabled: deviceApproval
				})
			);
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		}
		saving = false;
	}

	async function act(work: () => Promise<unknown>) {
		try {
			await work();
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	function addAddress(address: string) {
		ipList = ipList.trim() ? `${ipList.trim()}\n${address}` : address;
	}

	const eventLabel = (kind: SecurityEvent['kind']) =>
		({
			login_ok: tr('Prijava uspjela', 'Signed in'),
			login_failed: tr('Prijava nije uspjela', 'Failed sign-in'),
			login_locked: tr('Previše pokušaja', 'Too many attempts'),
			ip_blocked: tr('Adresa odbijena', 'Address refused'),
			device_blocked: tr('Uređaj nije odobren', 'Device not approved')
		})[kind];

	onMount(load);
</script>

<svelte:head><title>{tr('Sigurnost', 'Security')} — Mediarr Admin</title></svelte:head>

<div class="ph"><div><h1>{tr('Sigurnost', 'Security')}</h1></div></div>

{#if !settings}
	<Skeleton height="220px" />
{:else}
	<Card title={tr('Tko smije pristupiti', 'Who may connect')}>
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{tr('Server vas vidi s adrese', 'The server sees you at')} <b>{settings.yourAddress}</b>.
				{tr(
					'Ako je to adresa vašeg proxyja, a ne vaša, postavite TRUSTED_PROXY_HOPS.',
					'If that is your proxy and not you, set TRUSTED_PROXY_HOPS.'
				)}
			</p>
			<label>
				<input type="checkbox" bind:checked={ipEnabled} />
				{tr('Dopusti samo ove adrese i mreže', 'Allow only these addresses and networks')}
			</label>
			<label for="ip-list"
				>{tr('Jedna u retku, npr. 192.168.1.0/24', 'One a line, such as 192.168.1.0/24')}</label
			>
			<textarea id="ip-list" class="in" rows="5" bind:value={ipList}></textarea>
			<div>
				<Button small onclick={() => addAddress(settings?.yourAddress ?? '')}>
					{tr('Dodaj moju adresu', 'Add my address')}
				</Button>
			</div>
			<label>
				<input type="checkbox" bind:checked={deviceApproval} />
				{tr(
					'Novi uređaj se može prijaviti tek kad ga odobrim',
					'A new device can sign in only after I approve it'
				)}
			</label>
			<p class="alb-meta">
				{tr(
					'Ako se zaključate, na serveru pokrenite: docker compose exec server /mediarr security reset',
					'If you lock yourself out, run this on the server: docker compose exec server /mediarr security reset'
				)}
			</p>
			<div>
				<Button type="submit" variant="gold" small disabled={saving}>{tr('Spremi', 'Save')}</Button>
			</div>
		</form>
	</Card>

	<Card title={tr('Uređaji', 'Devices')}>
		{#if settings.devices.length === 0}
			<EmptyState icon="shield" text={tr('Još nema uređaja.', 'No devices yet.')} />
		{:else}
			<div class="audit-list">
				{#each settings.devices as device (device.id)}
					<div class="audit-row">
						<small>{new Date(device.lastSeen).toLocaleString()}</small>
						<b>{device.email}</b>
						<span>{device.ip} · {device.userAgent}</span>
						<span>
							{#if !device.approved}
								<Button
									small
									variant="gold"
									onclick={() => act(() => api.approveDevice(device.id))}
								>
									{tr('Odobri', 'Approve')}
								</Button>
							{/if}
							<Button small onclick={() => act(() => api.deleteDevice(device.id))}>
								{tr('Zaboravi', 'Forget')}
							</Button>
						</span>
					</div>
				{/each}
			</div>
		{/if}
	</Card>

	<Card title={tr('Pokušaji pristupa, od najnovijeg', 'Attempts to connect, newest first')}>
		{#if !events}
			<Skeleton height="120px" />
		{:else if events.length === 0}
			<EmptyState icon="shield" text={tr('Još nema zapisa.', 'Nothing recorded yet.')} />
		{:else}
			<div class="audit-list">
				{#each events as entry (entry.id)}
					<div class="audit-row" class:audit-failed={entry.kind !== 'login_ok'}>
						<small>{new Date(entry.at).toLocaleString()}</small>
						<b>{eventLabel(entry.kind)}</b>
						<span>{entry.email} {entry.ip}</span>
						<span>
							{entry.userAgent}
							{#if entry.ip}
								<Button small onclick={() => addAddress(entry.ip)}>
									{tr('Dodaj na listu', 'Add to the list')}
								</Button>
							{/if}
						</span>
					</div>
				{/each}
			</div>
		{/if}
	</Card>
{/if}
