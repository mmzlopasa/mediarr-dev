<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { api, ApiError } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import AuthLayout from '#lib/design/components/AuthLayout.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	let name = $state('');
	let email = $state('');
	let password = $state('');
	let error = $state('');
	let busy = $state(false);

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		error = '';
		try {
			await api.setup({ email, name, password });
			await goto(resolve('/(app)'), { invalidateAll: true });
		} catch (cause) {
			error = cause instanceof ApiError ? cause.message : t('setup.setupFailedPleaseTryAgain');
		} finally {
			busy = false;
		}
	}
</script>

<svelte:head><title>{t('setup.firstTimeSetup')} — Mediarr</title></svelte:head>

<AuthLayout>
	{#if error}<Alert kind="err">{error}</Alert>{/if}
	<h1 class="as-h">{t('setup.welcomeToMediarr')}</h1>
	<p class="as-p">
		{t('setup.createTheAdministratorAccount')}
	</p>
	<form class="as-f" onsubmit={submit}>
		<label class="as-fl">
			<span>{t('common.name2')}</span>
			<input class="as-in" name="name" required autocomplete="name" bind:value={name} />
		</label>
		<label class="as-fl">
			<span>{t('common.email')}</span>
			<input
				class="as-in"
				type="email"
				name="email"
				required
				autocomplete="username"
				bind:value={email}
			/>
		</label>
		<label class="as-fl">
			<span>{t('setup.passwordAtLeast12Characters')}</span>
			<input
				class="as-in"
				type="password"
				name="password"
				required
				minlength="12"
				autocomplete="new-password"
				bind:value={password}
			/>
		</label>
		<button class="as-btn" type="submit" disabled={busy}>{t('setup.createAccount')}</button>
	</form>
</AuthLayout>
