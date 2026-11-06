<script lang="ts">
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import type { PageProps } from './$types';
	import {
		api,
		ApiError,
		type ApiKey,
		type AuthMethods,
		type Passkey,
		type TotpSetup
	} from '#lib/api.ts';
	import { registerPasskey } from '#lib/passkeys.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import AccountOverview from '#lib/organize/AccountOverview.svelte';
	import PreferencesCard from '#lib/organize/PreferencesCard.svelte';
	import SessionsCard from '#lib/organize/SessionsCard.svelte';
	import SectionNav from '#lib/design/components/SectionNav.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let { data }: PageProps = $props();

	let currentPassword = $state('');
	let newPassword = $state('');
	let passwordError = $state('');

	let totp = $state<TotpSetup>();
	let code = $state('');
	let disablePassword = $state('');
	let totpError = $state('');

	const SCOPES: { id: ApiKey['scopes'][number]; hr: string; en: string }[] = [
		{ id: 'read', hr: 'Čitanje', en: 'Read' },
		{ id: 'upload', hr: 'Slanje datoteka', en: 'Upload' },
		{ id: 'write', hr: 'Izmjene i brisanje', en: 'Change and delete' },
		{ id: 'admin', hr: 'Administracija', en: 'Administration' }
	];
	let keys = $state<ApiKey[]>();
	let keyName = $state('');
	let keyScopes = $state<ApiKey['scopes']>(['read']);
	let keyDays = $state('');
	let newKey = $state('');
	let keyError = $state('');

	async function loadKeys() {
		try {
			keys = await api.apiKeys();
		} catch (cause) {
			keyError = message(cause);
		}
	}

	let methods = $state<AuthMethods>();
	let passkeys = $state<Passkey[]>([]);
	let passkeyName = $state('');
	let passkeyPassword = $state('');
	let passkeyError = $state('');

	async function loadPasskeys() {
		passkeys = await api.passkeys();
	}

	onMount(async () => {
		await loadKeys();
		try {
			methods = await api.authMethods();
			if (methods.passkeys) await loadPasskeys();
		} catch (cause) {
			passkeyError = message(cause);
		}
	});

	async function addPasskey(event: SubmitEvent) {
		event.preventDefault();
		passkeyError = '';
		try {
			await registerPasskey(passkeyName, passkeyPassword);
			passkeyPassword = '';
			passkeyName = '';
			await loadPasskeys();
		} catch (cause) {
			passkeyError = cause instanceof Error ? cause.message : message(cause);
		}
	}

	async function removePasskey(id: string) {
		try {
			await api.deletePasskey(id);
			await loadPasskeys();
		} catch (cause) {
			passkeyError = message(cause);
		}
	}

	async function createKey(event: SubmitEvent) {
		event.preventDefault();
		keyError = '';
		try {
			const made = await api.createApiKey(
				keyName,
				keyScopes,
				keyDays ? Number(keyDays) : undefined
			);
			newKey = made.key;
			keyName = '';
			keyDays = '';
			await loadKeys();
		} catch (cause) {
			keyError = message(cause);
		}
	}

	async function revokeKey(id: string) {
		try {
			await api.revokeApiKey(id);
			await loadKeys();
		} catch (cause) {
			keyError = message(cause);
		}
	}

	const message = (cause: unknown) =>
		cause instanceof ApiError ? cause.message : tr('Nešto nije u redu.', 'Something went wrong.');

	async function changePassword(event: SubmitEvent) {
		event.preventDefault();
		passwordError = '';
		try {
			await api.changePassword({ currentPassword, newPassword });
			currentPassword = '';
			newPassword = '';
			showToast('ok', tr('Lozinka je promijenjena.', 'The password was changed.'));
		} catch (cause) {
			passwordError = message(cause);
		}
	}

	async function startTotp() {
		totpError = '';
		try {
			totp = await api.setupTotp();
		} catch (cause) {
			totpError = message(cause);
		}
	}

	async function enableTotp(event: SubmitEvent) {
		event.preventDefault();
		totpError = '';
		try {
			await api.enableTotp(code);
			totp = undefined;
			code = '';
			await invalidate('app:session');
			showToast('ok', tr('Dvofaktorska prijava je uključena.', 'Two-factor sign-in is on.'));
		} catch (cause) {
			totpError = message(cause);
		}
	}

	async function disableTotp(event: SubmitEvent) {
		event.preventDefault();
		totpError = '';
		try {
			await api.disableTotp(disablePassword);
			disablePassword = '';
			await invalidate('app:session');
			showToast('ok', tr('Dvofaktorska prijava je isključena.', 'Two-factor sign-in is off.'));
		} catch (cause) {
			totpError = message(cause);
		}
	}
</script>

<svelte:head><title>{tr('Račun', 'Account')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr('Račun', 'Account')}</h1>
		<p>{data.user.name} · {data.user.email}</p>
	</div>
</div>

<div class="set">
	<SectionNav
		items={[
			{ id: 'library', label: tr('Biblioteka', 'Library') },
			{ id: 'preferences', label: tr('Postavke', 'Preferences') },
			{ id: 'security', label: tr('Lozinka i prijava', 'Password and sign-in') },
			{ id: 'devices', label: tr('Uređaji', 'Devices') },
			{ id: 'keys', label: tr('API ključevi', 'API keys') }
		]}
	/>
	<div class="set-body">
		<AccountOverview />

		<PreferencesCard />

		<Card id="security" title={tr('Lozinka i prijava', 'Password and sign-in')}>
			<div class="set-group">
				<h3>{tr('Lozinka', 'Password')}</h3>
				{#if passwordError}<Alert kind="err">{passwordError}</Alert>{/if}
				<form class="form" onsubmit={changePassword}>
					<Input
						label={tr('Trenutna lozinka', 'Current password')}
						type="password"
						autocomplete="current-password"
						required
						bind:value={currentPassword}
					/>
					<Input
						label={tr('Nova lozinka', 'New password')}
						hint={tr('Najmanje 12 znakova.', 'At least 12 characters.')}
						type="password"
						autocomplete="new-password"
						minlength={12}
						required
						bind:value={newPassword}
					/>
					<div class="set-foot">
						<Button type="submit" variant="gold" small
							>{tr('Promijeni lozinku', 'Change password')}</Button
						>
					</div>
				</form>
			</div>

			<div class="set-group">
				<h3>{tr('Dvofaktorska prijava', 'Two-factor sign-in')}</h3>
				{#if totpError}<Alert kind="err">{totpError}</Alert>{/if}
				{#if data.user.totpEnabled}
					<form class="form" onsubmit={disableTotp}>
						<p class="set-line">
							<em class="set-chip ok">{tr('Uključena', 'On')}</em>
							{tr(
								'Uz lozinku se traži i kod iz aplikacije.',
								'A code from your app is asked for as well as the password.'
							)}
						</p>
						<Input
							label={tr('Lozinka za potvrdu', 'Password to confirm')}
							type="password"
							autocomplete="current-password"
							required
							bind:value={disablePassword}
						/>
						<div class="set-foot">
							<Button type="submit" variant="danger" small>{tr('Isključi', 'Turn off')}</Button>
						</div>
					</form>
				{:else if totp}
					<form class="form" onsubmit={enableTotp}>
						<p class="set-line">
							{tr(
								'Dodajte ovaj ključ u aplikaciju za autentifikaciju, pa unesite kod.',
								'Add this key to your authenticator app, then enter the code.'
							)}
						</p>
						<code class="block">{totp.secret}</code>
						<Input
							label={tr('Kod', 'Code')}
							inputmode="numeric"
							autocomplete="one-time-code"
							required
							bind:value={code}
						/>
						<div class="set-foot">
							<Button type="submit" variant="gold" small>{tr('Uključi', 'Turn on')}</Button>
						</div>
					</form>
				{:else}
					<div class="set-row">
						<span>
							{tr(
								'Uz lozinku traži i kod iz aplikacije za autentifikaciju.',
								'Asks for a code from an authenticator app as well as your password.'
							)}
						</span>
						<Button small onclick={startTotp}>{tr('Postavi', 'Set up')}</Button>
					</div>
				{/if}
			</div>

			{#if methods?.passkeys}
				<div class="set-group">
					<h3>Passkeys</h3>
					{#if passkeyError}<Alert kind="err">{passkeyError}</Alert>{/if}
					{#if passkeys.length}
						<ul class="set-list">
							{#each passkeys as key (key.id)}
								<li>
									<span class="set-list-ic"><Icon name="key" /></span>
									<span class="set-list-t"><b>{key.name}</b></span>
									<Button small onclick={() => removePasskey(key.id)}
										>{tr('Ukloni', 'Remove')}</Button
									>
								</li>
							{/each}
						</ul>
					{/if}
					<form class="form" onsubmit={addPasskey}>
						<Input label={tr('Naziv passkeya', 'Passkey name')} bind:value={passkeyName} />
						<Input
							label={tr('Vaša lozinka', 'Your password')}
							type="password"
							autocomplete="current-password"
							bind:value={passkeyPassword}
						/>
						<div class="set-foot">
							<Button type="submit" variant="gold" small
								>{tr('Dodaj passkey', 'Add a passkey')}</Button
							>
						</div>
					</form>
				</div>
			{/if}
		</Card>

		<SessionsCard />

		<Card
			id="keys"
			title={tr('API ključevi', 'API keys')}
			note={tr(
				'Ključ daje programu samo odabrana prava i ne može upravljati računom. Promjena lozinke opoziva sve ključeve.',
				'A key gives a program only the chosen rights, and cannot manage the account. Changing the password revokes all keys.'
			)}
		>
			{#if keyError}<Alert kind="err">{keyError}</Alert>{/if}
			{#if newKey}
				<Alert kind="ok"
					>{tr(
						'Spremite ga sada, jer se više neće prikazati:',
						'Save it now, because it will not be shown again:'
					)} <code data-testid="new-key">{newKey}</code></Alert
				>
			{/if}
			{#if keys?.length}
				<ul class="set-list">
					{#each keys as key (key.id)}
						<li>
							<span class="set-list-ic"><Icon name="key" /></span>
							<span class="set-list-t">
								<b>{key.name}</b>
								<small>
									{key.scopes
										.map((id) => {
											const scope = SCOPES.find((one) => one.id === id);
											return scope ? tr(scope.hr, scope.en) : id;
										})
										.join(', ')}
									{#if key.expiresAt}· {tr('istječe', 'expires')}
										{new Date(key.expiresAt).toLocaleDateString()}{/if}
								</small>
							</span>
							<Button small onclick={() => revokeKey(key.id)}>{tr('Opozovi', 'Revoke')}</Button>
						</li>
					{/each}
				</ul>
			{/if}
			<div class="set-group">
				<h3>{tr('Novi ključ', 'New key')}</h3>
				<form class="form" onsubmit={createKey}>
					<Input label={tr('Naziv ključa', 'Key name')} bind:value={keyName} />
					<fieldset class="set-row set-field">
						<legend>{tr('Prava', 'Rights')}</legend>
						<div class="set-checks">
							{#each SCOPES as scope (scope.id)}
								{#if scope.id !== 'admin' || data.user.isAdmin}
									<label class="set-check">
										<input type="checkbox" bind:group={keyScopes} value={scope.id} />
										{tr(scope.hr, scope.en)}
									</label>
								{/if}
							{/each}
						</div>
					</fieldset>
					<Input
						label={tr('Istječe za dana (po želji)', 'Expires in days (optional)')}
						inputmode="numeric"
						bind:value={keyDays}
					/>
					<div class="set-foot">
						<Button type="submit" variant="gold" small>{tr('Stvori ključ', 'Create a key')}</Button>
					</div>
				</form>
			</div>
		</Card>
	</div>
</div>
