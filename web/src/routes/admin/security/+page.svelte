<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type SecurityEvent, type SecuritySettings } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

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
			showToast('err', t('common.thisCouldNotBeLoaded'));
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
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
		saving = false;
	}

	async function act(work: () => Promise<unknown>) {
		try {
			await work();
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	function addAddress(address: string) {
		ipList = ipList.trim() ? `${ipList.trim()}\n${address}` : address;
	}

	const eventLabel = (kind: SecurityEvent['kind']) =>
		({
			login_ok: t('admin.security.signedIn'),
			login_failed: t('admin.security.failedSignIn'),
			login_locked: t('admin.security.tooManyAttempts'),
			ip_blocked: t('admin.security.addressRefused'),
			device_blocked: t('admin.security.deviceNotApproved'),
			password_reset: t('common.newPassword')
		})[kind];

	onMount(load);
</script>

<svelte:head><title>{t('admin.security.security')} — Mediarr Admin</title></svelte:head>

<div class="ph"><div><h1>{t('admin.security.security')}</h1></div></div>

{#if !settings}
	<Skeleton height="220px" />
{:else}
	<Card title={t('admin.security.whoMayConnect')}>
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{t('admin.security.theServerSeesYouAt')} <b>{settings.yourAddress}</b>.
				{t('admin.security.ifThatIsYourProxy')}
			</p>
			<label>
				<input type="checkbox" bind:checked={ipEnabled} />
				{t('admin.security.allowOnlyTheseAddressesAnd')}
			</label>
			<label for="ip-list">{t('admin.security.oneALineSuchAs')}</label>
			<textarea id="ip-list" class="in" rows="5" bind:value={ipList}></textarea>
			<div>
				<Button small onclick={() => addAddress(settings?.yourAddress ?? '')}>
					{t('admin.security.addMyAddress')}
				</Button>
			</div>
			<label>
				<input type="checkbox" bind:checked={deviceApproval} />
				{t('admin.security.aNewDeviceCanSign')}
			</label>
			<p class="alb-meta">
				{t('admin.security.ifYouLockYourselfOut')}
			</p>
			<div>
				<Button type="submit" variant="gold" small disabled={saving}>{t('common.save')}</Button>
			</div>
		</form>
	</Card>

	<Card title={t('common.devices')}>
		{#if settings.devices.length === 0}
			<EmptyState icon="shield" text={t('admin.security.noDevicesYet')} />
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
									{t('admin.security.approve')}
								</Button>
							{/if}
							<Button small onclick={() => act(() => api.deleteDevice(device.id))}>
								{t('admin.security.forget')}
							</Button>
						</span>
					</div>
				{/each}
			</div>
		{/if}
	</Card>

	<Card title={t('admin.security.attemptsToConnectNewestFirst')}>
		{#if !events}
			<Skeleton height="120px" />
		{:else if events.length === 0}
			<EmptyState icon="shield" text={t('admin.security.nothingRecordedYet')} />
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
									{t('admin.security.addToTheList')}
								</Button>
							{/if}
						</span>
					</div>
				{/each}
			</div>
		{/if}
	</Card>
{/if}
