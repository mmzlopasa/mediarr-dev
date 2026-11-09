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
	import ProfileCard from '#lib/organize/ProfileCard.svelte';
	import PreferencesCard from '#lib/organize/PreferencesCard.svelte';
	import SessionsCard from '#lib/organize/SessionsCard.svelte';
	import SectionNav from '#lib/design/components/SectionNav.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t, k, type Key } from '#lib/i18n.svelte.ts';

	let { data }: PageProps = $props();

	let currentPassword = $state('');
	let newPassword = $state('');
	let passwordError = $state('');

	let totp = $state<TotpSetup>();
	let code = $state('');
	let disablePassword = $state('');
	let totpError = $state('');

	const SCOPES: { id: ApiKey['scopes'][number]; label: Key }[] = [
		{ id: 'read', label: k('account.read') },
		{ id: 'upload', label: k('account.upload') },
		{ id: 'write', label: k('account.changeAndDelete') },
		{ id: 'admin', label: k('home.administration') }
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
		cause instanceof ApiError ? cause.message : t('account.somethingWentWrong');

	async function changePassword(event: SubmitEvent) {
		event.preventDefault();
		passwordError = '';
		try {
			await api.changePassword({ currentPassword, newPassword });
			currentPassword = '';
			newPassword = '';
			showToast('ok', t('account.thePasswordWasChanged'));
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
			showToast('ok', t('account.twoFactorSignInIs'));
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
			showToast('ok', t('account.twoFactorSignInIs2'));
		} catch (cause) {
			totpError = message(cause);
		}
	}
</script>

<svelte:head><title>{t('common.account')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t('common.account')}</h1>
		<p>{data.user.name} · {data.user.email}</p>
	</div>
</div>

<div class="set">
	<SectionNav
		items={[
			{ id: 'profile', label: t('account.profile') },
			{ id: 'library', label: t('account.library') },
			{ id: 'preferences', label: t('account.preferences') },
			{ id: 'security', label: t('account.passwordAndSignIn') },
			{ id: 'devices', label: t('common.devices') },
			{ id: 'keys', label: t('account.apiKeys') }
		]}
	/>
	<div class="set-body">
		<ProfileCard user={data.user} />

		<AccountOverview />

		<PreferencesCard />

		<Card id="security" title={t('account.passwordAndSignIn')}>
			<div class="set-group">
				<h3>{t('common.password')}</h3>
				{#if passwordError}<Alert kind="err">{passwordError}</Alert>{/if}
				<form class="form" onsubmit={changePassword}>
					<Input
						label={t('account.currentPassword')}
						type="password"
						autocomplete="current-password"
						required
						bind:value={currentPassword}
					/>
					<Input
						label={t('common.newPassword')}
						hint={t('account.atLeast12Characters')}
						type="password"
						autocomplete="new-password"
						minlength={12}
						required
						bind:value={newPassword}
					/>
					<div class="set-foot">
						<Button type="submit" variant="gold" small>{t('account.changePassword')}</Button>
					</div>
				</form>
			</div>

			<div class="set-group">
				<h3>{t('account.twoFactorSignIn')}</h3>
				{#if totpError}<Alert kind="err">{totpError}</Alert>{/if}
				{#if data.user.totpEnabled}
					<form class="form" onsubmit={disableTotp}>
						<p class="set-line">
							<em class="set-chip ok">{t('account.on')}</em>
							{t('account.aCodeFromYourApp')}
						</p>
						<Input
							label={t('account.passwordToConfirm')}
							type="password"
							autocomplete="current-password"
							required
							bind:value={disablePassword}
						/>
						<div class="set-foot">
							<Button type="submit" variant="danger" small>{t('account.turnOff')}</Button>
						</div>
					</form>
				{:else if totp}
					<form class="form" onsubmit={enableTotp}>
						<p class="set-line">
							{t('account.addThisKeyToYour')}
						</p>
						<code class="block">{totp.secret}</code>
						<Input
							label={t('account.code')}
							inputmode="numeric"
							autocomplete="one-time-code"
							required
							bind:value={code}
						/>
						<div class="set-foot">
							<Button type="submit" variant="gold" small>{t('account.turnOn')}</Button>
						</div>
					</form>
				{:else}
					<div class="set-row">
						<span>
							{t('account.asksForACodeFrom')}
						</span>
						<Button small onclick={startTotp}>{t('account.setUp')}</Button>
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
									<Button small onclick={() => removePasskey(key.id)}>{t('common.remove')}</Button>
								</li>
							{/each}
						</ul>
					{/if}
					<form class="form" onsubmit={addPasskey}>
						<Input label={t('account.passkeyName')} bind:value={passkeyName} />
						<Input
							label={t('account.yourPassword')}
							type="password"
							autocomplete="current-password"
							bind:value={passkeyPassword}
						/>
						<div class="set-foot">
							<Button type="submit" variant="gold" small>{t('account.addAPasskey')}</Button>
						</div>
					</form>
				</div>
			{/if}
		</Card>

		<SessionsCard />

		<Card id="keys" title={t('account.apiKeys')} note={t('account.aKeyGivesAProgram')}>
			{#if keyError}<Alert kind="err">{keyError}</Alert>{/if}
			{#if newKey}
				<Alert kind="ok"
					>{t('account.saveItNowBecauseIt')} <code data-testid="new-key">{newKey}</code></Alert
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
											return scope ? t(scope.label) : id;
										})
										.join(', ')}
									{#if key.expiresAt}· {t('account.expires')}
										{new Date(key.expiresAt).toLocaleDateString()}{/if}
								</small>
							</span>
							<Button small onclick={() => revokeKey(key.id)}>{t('account.revoke')}</Button>
						</li>
					{/each}
				</ul>
			{/if}
			<div class="set-group">
				<h3>{t('account.newKey')}</h3>
				<form class="form" onsubmit={createKey}>
					<Input label={t('account.keyName')} bind:value={keyName} />
					<fieldset class="set-row set-field">
						<legend>{t('account.rights')}</legend>
						<div class="set-checks">
							{#each SCOPES as scope (scope.id)}
								{#if scope.id !== 'admin' || data.user.isAdmin}
									<label class="set-check">
										<input type="checkbox" bind:group={keyScopes} value={scope.id} />
										{t(scope.label)}
									</label>
								{/if}
							{/each}
						</div>
					</fieldset>
					<Input
						label={t('account.expiresInDaysOptional')}
						inputmode="numeric"
						bind:value={keyDays}
					/>
					<div class="set-foot">
						<Button type="submit" variant="gold" small>{t('account.createAKey')}</Button>
					</div>
				</form>
			</div>
		</Card>
	</div>
</div>
