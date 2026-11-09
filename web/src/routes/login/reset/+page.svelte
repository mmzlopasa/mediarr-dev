<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api } from '#lib/api.ts';
	import AuthLayout from '#lib/design/components/AuthLayout.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	let password = $state('');
	let done = $state(false);
	let error = $state('');
	let busy = $state(false);

	async function submit(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		error = '';
		try {
			await api.resetPassword({
				token: page.url.searchParams.get('token') ?? '',
				newPassword: password
			});
			done = true;
		} catch (cause) {
			error = cause instanceof Error ? cause.message : t('login.reset.thatDidNotWork');
		}
		busy = false;
	}
</script>

<svelte:head><title>{t('common.newPassword')} — Mediarr</title></svelte:head>

<AuthLayout>
	<h1 class="as-h">{t('common.newPassword')}</h1>
	{#if done}
		<p class="as-p">
			{t('login.reset.yourPasswordWasChangedAnd')}
		</p>
		<p class="as-links"><a href={resolve('/login')}>{t('login.reset.signIn')}</a></p>
	{:else}
		{#if error}<p class="as-p" role="alert">{error}</p>{/if}
		<form class="as-f" onsubmit={submit}>
			<label class="as-fl">
				<span>{t('common.newPassword')}</span>
				<input
					class="as-in"
					type="password"
					required
					minlength="12"
					autocomplete="new-password"
					bind:value={password}
				/>
			</label>
			<button class="as-btn" type="submit" disabled={busy}>
				{t('common.save')}
			</button>
		</form>
	{/if}
</AuthLayout>
