<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { onMount } from 'svelte';
	import { api, ApiError, type AuthMethods } from '#lib/api.ts';
	import { signInWithPasskey } from '#lib/passkeys.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import AuthLayout from '#lib/design/components/AuthLayout.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	const CODE_PATTERN = '[0-9 ]{6,7}';

	let email = $state('');
	let password = $state('');
	let code = $state('');
	let needsCode = $state(false);
	let visible = $state(false);
	let error = $state('');
	let showForgot = $state(false);
	let busy = $state(false);

	let methods = $state<AuthMethods>();

	onMount(async () => {
		try {
			methods = await api.authMethods();
		} catch {
			// The form below still works.
		}
		if (page.url.searchParams.get('sso') === 'failed') {
			error = tr(
				'Jedinstvena prijava nije uspjela. Možda nemate račun na ovom serveru.',
				'Single sign-on did not work. You may not have an account on this server.'
			);
		}
	});

	async function passkey() {
		busy = true;
		error = '';
		try {
			await signInWithPasskey();
			// eslint-disable-next-line svelte/no-navigation-without-resolve -- validated local path
			await goto(nextPath(), { invalidateAll: true });
		} catch {
			error = tr('Prijava passkeyem nije uspjela.', 'Signing in with a passkey did not work.');
		} finally {
			busy = false;
		}
	}

	// Only local paths, so a crafted link cannot send the user to another site after sign-in.
	function nextPath() {
		const next = page.url.searchParams.get('next') ?? '';
		// Browsers drop tabs and line breaks from addresses, so "/<tab>/evil" would become "//evil".
		// eslint-disable-next-line no-control-regex
		if (/[\u0000-\u001f\u007f]/.test(next)) return '/';
		return next.startsWith('/') && !next.startsWith('//') && !next.startsWith('/\\') ? next : '/';
	}

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		error = '';
		try {
			await api.login({ email, password, totpCode: needsCode ? code : undefined });
			// eslint-disable-next-line svelte/no-navigation-without-resolve -- validated local path
			await goto(nextPath(), { invalidateAll: true });
		} catch (cause) {
			if (cause instanceof ApiError && cause.totpRequired) {
				if (needsCode) error = tr('Kod nije točan.', 'The code is wrong.');
				needsCode = true;
				code = '';
			} else if (cause instanceof ApiError && cause.status === 429) {
				error = tr('Previše pokušaja. Pokušajte kasnije.', 'Too many attempts. Try again later.');
			} else if (cause instanceof ApiError && cause.status === 401) {
				error = tr('Pogrešna e-adresa ili lozinka.', 'Wrong email or password.');
			} else {
				error = tr('Prijava nije uspjela. Pokušajte ponovno.', 'Sign-in failed. Please try again.');
			}
		} finally {
			busy = false;
		}
	}
</script>

<svelte:head><title>{tr('Prijava', 'Sign in')} — Mediarr</title></svelte:head>

<AuthLayout>
	{#if error}<Alert kind="err">{error}</Alert>{/if}
	{#if needsCode}
		<h1 class="as-h">{tr('Dvofaktorska prijava', 'Two-factor sign-in')}</h1>
		<p class="as-p">
			{tr(
				'Unesite 6-znamenkasti kod iz aplikacije za autentifikaciju.',
				'Enter the 6-digit code from your authenticator app.'
			)}
		</p>
		<form class="as-f" autocomplete="off" onsubmit={submit}>
			<label class="as-fl">
				<span>{tr('Kod', 'Code')}</span>
				<input
					class="as-in code-in"
					name="code"
					inputmode="numeric"
					pattern={CODE_PATTERN}
					maxlength="7"
					required
					autocomplete="one-time-code"
					bind:value={code}
				/>
			</label>
			<button class="as-btn" type="submit" disabled={busy}>{tr('Potvrdi', 'Verify')}</button>
		</form>
		<p class="as-links">
			<a href={resolve('/login')} onclick={() => (needsCode = false)}>{tr('← Natrag', '← Back')}</a>
		</p>
	{:else}
		<h1 class="as-h">{tr('Dobrodošli', 'Welcome')}</h1>
		<p class="as-p">{tr('Prijavite se svojim računom.', 'Sign in with your account.')}</p>
		{#if methods?.loginMessage}<p class="as-p login-note">{methods.loginMessage}</p>{/if}
		{#if methods?.passwordLogin !== false}<form class="as-f" autocomplete="on" onsubmit={submit}>
				<label class="as-fl">
					<span>{tr('E-adresa', 'Email')}</span>
					<input
						class="as-in"
						type="email"
						name="email"
						required
						autocomplete="username"
						inputmode="email"
						bind:value={email}
					/>
				</label>
				<label class="as-fl">
					<span>{tr('Lozinka', 'Password')}</span>
					<span class="as-pw">
						<input
							class="as-in"
							type={visible ? 'text' : 'password'}
							name="password"
							required
							autocomplete="current-password"
							bind:value={password}
						/>
						<button
							type="button"
							class="as-eye"
							aria-label={tr('Prikaži lozinku', 'Show password')}
							aria-pressed={visible}
							onclick={() => (visible = !visible)}><Icon name="eye" /></button
						>
					</span>
				</label>
				<button class="as-btn" type="submit" disabled={busy}>{tr('Prijavi se', 'Sign in')}</button>
			</form>{/if}
		{#if methods?.ssoLabel}
			<a
				class="as-btn"
				rel="external"
				href="/api/auth/oidc/start?next={encodeURIComponent(nextPath())}">{methods.ssoLabel}</a
			>
		{/if}
		{#if methods?.passkeys}
			<button class="as-btn" type="button" disabled={busy} onclick={passkey}
				>{tr('Prijava passkeyem', 'Sign in with a passkey')}</button
			>
		{/if}
		<p class="as-links">
			<a
				href="#forgot"
				onclick={(event) => {
					event.preventDefault();
					showForgot = true;
				}}>{tr('Zaboravljena lozinka?', 'Forgot your password?')}</a
			>
		</p>
		{#if showForgot}
			<p class="as-p">
				{tr(
					'Administrator poslužitelja može je postaviti naredbom: mediarr user upsert',
					'The server administrator can reset it with the command: mediarr user upsert'
				)}
			</p>
		{/if}
	{/if}
</AuthLayout>
