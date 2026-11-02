<script lang="ts">
	import { invalidate } from '$app/navigation';
	import type { PageProps } from './$types';
	import { api, ApiError, type TotpSetup } from '#lib/api.ts';
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
