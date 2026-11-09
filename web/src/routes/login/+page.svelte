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
	import { magnet, revealTitle } from '#lib/motion/actions.ts';
	import { t } from '#lib/i18n.svelte.ts';

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
			error = t('login.singleSignOnDidNot');
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
			error = t('login.signingInWithAPasskey');
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

	let forgotSent = $state(false);

	async function forgot() {
		try {
			await api.forgotPassword(email);
		} catch {
			// The same answer either way, so that this does not tell who has an account.
		}
		forgotSent = true;
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
				if (needsCode) error = t('login.theCodeIsWrong');
				needsCode = true;
				code = '';
			} else if (cause instanceof ApiError && cause.status === 429) {
				error = t('common.tooManyAttemptsTryAgain');
			} else if (cause instanceof ApiError && cause.status === 401) {
				error = t('login.wrongEmailOrPassword');
			} else {
				error = t('login.signInFailedPleaseTry');
			}
		} finally {
			busy = false;
		}
	}
</script>

<svelte:head><title>{t('login.signIn')} — Mediarr</title></svelte:head>

<AuthLayout>
	{#if error}<Alert kind="err">{error}</Alert>{/if}
	{#if needsCode}
		<h1 class="as-h">{t('login.twoFactorSignIn')}</h1>
		<p class="as-p">
			{t('login.enterThe6DigitCode')}
		</p>
		<form class="as-f" autocomplete="off" onsubmit={submit}>
			<label class="as-fl">
				<span>{t('login.code')}</span>
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
			<button class="as-btn" type="submit" disabled={busy}>{t('login.verify')}</button>
		</form>
		<p class="as-links">
			<a href={resolve('/login')} onclick={() => (needsCode = false)}>{t('login.back')}</a>
		</p>
	{:else}
		<h1 class="as-h" use:revealTitle>{t('login.welcome')}</h1>
		{#if methods && methods.serverName !== 'Mediarr'}<p class="as-p login-server">
				{methods.serverName}
			</p>{/if}
		<p class="as-p">{t('login.signInWithYourAccount')}</p>
		{#if methods?.maintenance}<p class="as-p login-note">
				{t('login.thisServerIsBeingMaintained')}
			</p>{/if}
		{#if methods?.loginMessage}<p class="as-p login-note">{methods.loginMessage}</p>{/if}
		{#if methods?.passwordLogin !== false}<form class="as-f" autocomplete="on" onsubmit={submit}>
				<label class="as-fl">
					<span>{t('common.email')}</span>
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
					<span>{t('common.password')}</span>
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
							aria-label={t('login.showPassword')}
							aria-pressed={visible}
							onclick={() => (visible = !visible)}><Icon name="eye" /></button
						>
					</span>
				</label>
				<button class="as-btn" type="submit" disabled={busy} use:magnet={{ most: 5 }}
					>{t('login.signIn2')}</button
				>
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
				>{t('login.signInWithAPasskey')}</button
			>
		{/if}
		<p class="as-links">
			<a
				href="#forgot"
				onclick={(event) => {
					event.preventDefault();
					showForgot = true;
				}}>{t('login.forgotYourPassword')}</a
			>
		</p>
		{#if showForgot && methods?.passwordReset}
			{#if forgotSent}
				<p class="as-p" role="status">
					{t('login.ifThatAddressHasAn')}
				</p>
			{:else}
				<button class="as-btn" type="button" disabled={!email || busy} onclick={forgot}>
					{t('login.sendALinkToThe')}
				</button>
			{/if}
		{:else if showForgot}
			<p class="as-p">
				{t('login.theServerAdministratorCanReset')}
			</p>
		{/if}
	{/if}
</AuthLayout>
