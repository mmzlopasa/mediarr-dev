<script lang="ts">
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import type { PageProps } from './$types';
	import { api, ApiError, type ApiKey, type TotpSetup } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
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

	onMount(loadKeys);

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
		<p>{data.user.email}</p>
	</div>
</div>

<div class="grid2">
	<Card title={tr('Lozinka', 'Password')}>
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
			<div class="btn-row">
				<Button type="submit" variant="gold">{tr('Promijeni lozinku', 'Change password')}</Button>
			</div>
		</form>
	</Card>

	<Card title={tr('API ključevi', 'API keys')}>
		<p class="alb-meta">
			{tr(
				'Ključ daje programu samo odabrana prava i ne može upravljati računom. Promjena lozinke opoziva sve ključeve.',
				'A key gives a program only the chosen rights, and cannot manage the account. Changing the password revokes all keys.'
			)}
		</p>
		{#if keyError}<Alert kind="err">{keyError}</Alert>{/if}
		{#if newKey}
			<Alert kind="ok"
				>{tr(
					'Spremite ga sada, jer se više neće prikazati:',
					'Save it now, because it will not be shown again:'
				)} <code data-testid="new-key">{newKey}</code></Alert
			>
		{/if}
		{#each keys ?? [] as key (key.id)}
			<div class="alb-list">
				<b>{key.name}</b>
				<span class="alb-meta">
					{key.scopes.join(', ')}
					{#if key.expiresAt}· {tr('istječe', 'expires')}
						{new Date(key.expiresAt).toLocaleDateString()}{/if}
				</span>
				<Button small onclick={() => revokeKey(key.id)}>{tr('Opozovi', 'Revoke')}</Button>
			</div>
		{/each}
		<form class="form" onsubmit={createKey}>
			<Input label={tr('Naziv ključa', 'Key name')} bind:value={keyName} />
			{#each SCOPES as scope (scope.id)}
				{#if scope.id !== 'admin' || data.user.isAdmin}
					<label>
						<input type="checkbox" bind:group={keyScopes} value={scope.id} />
						{tr(scope.hr, scope.en)}
					</label>
				{/if}
			{/each}
			<Input
				label={tr('Istječe za dana (po želji)', 'Expires in days (optional)')}
				bind:value={keyDays}
			/>
			<Button type="submit" variant="gold" small>{tr('Stvori ključ', 'Create a key')}</Button>
		</form>
	</Card>

	<Card title={tr('Dvofaktorska prijava', 'Two-factor sign-in')}>
		{#if totpError}<Alert kind="err">{totpError}</Alert>{/if}
		{#if data.user.totpEnabled}
			<form class="form" onsubmit={disableTotp}>
				<p class="mute">{tr('Uključena je.', 'It is on.')}</p>
				<Input
					label={tr('Lozinka za potvrdu', 'Password to confirm')}
					type="password"
					autocomplete="current-password"
					required
					bind:value={disablePassword}
				/>
				<div class="btn-row">
					<Button type="submit" variant="danger">{tr('Isključi', 'Turn off')}</Button>
				</div>
			</form>
		{:else if totp}
			<form class="form" onsubmit={enableTotp}>
				<p class="mute">
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
				<div class="btn-row">
					<Button type="submit" variant="gold">{tr('Uključi', 'Turn on')}</Button>
				</div>
			</form>
		{:else}
			<p class="mute">
				{tr(
					'Uz lozinku traži i kod iz aplikacije za autentifikaciju.',
					'Asks for a code from an authenticator app as well as your password.'
				)}
			</p>
			<div class="btn-row">
				<Button variant="gold" onclick={startTotp}>{tr('Postavi', 'Set up')}</Button>
			</div>
		{/if}
	</Card>
</div>
