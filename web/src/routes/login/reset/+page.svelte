<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api } from '#lib/api.ts';
	import AuthLayout from '#lib/design/components/AuthLayout.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

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
			error = cause instanceof Error ? cause.message : tr('Nije uspjelo.', 'That did not work.');
		}
		busy = false;
	}
</script>

<svelte:head><title>{tr('Nova lozinka', 'New password')} — Mediarr</title></svelte:head>

<AuthLayout>
	<h1 class="as-h">{tr('Nova lozinka', 'New password')}</h1>
	{#if done}
		<p class="as-p">
			{tr(
				'Lozinka je promijenjena, a ostali uređaji su odjavljeni.',
				'Your password was changed, and other devices were signed out.'
			)}
		</p>
		<p class="as-links"><a href={resolve('/login')}>{tr('Prijava', 'Sign in')}</a></p>
	{:else}
		{#if error}<p class="as-p" role="alert">{error}</p>{/if}
		<form class="as-f" onsubmit={submit}>
			<label class="as-fl">
				<span>{tr('Nova lozinka', 'New password')}</span>
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
				{tr('Spremi', 'Save')}
			</button>
		</form>
	{/if}
</AuthLayout>
