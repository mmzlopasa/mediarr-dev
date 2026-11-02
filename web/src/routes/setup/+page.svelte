<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { api, ApiError } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import AuthLayout from '#lib/design/components/AuthLayout.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

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
			error =
				cause instanceof ApiError
					? cause.message
					: tr('Postavljanje nije uspjelo.', 'Setup failed. Please try again.');
		} finally {
			busy = false;
		}
	}
</script>

<svelte:head><title>{tr('Prvo postavljanje', 'First-time setup')} — Mediarr</title></svelte:head>

<AuthLayout>
	{#if error}<Alert kind="err">{error}</Alert>{/if}
	<h1 class="as-h">{tr('Dobrodošli u Mediarr', 'Welcome to Mediarr')}</h1>
	<p class="as-p">
		{tr('Napravite administratorski račun.', 'Create the administrator account.')}
	</p>
	<form class="as-f" onsubmit={submit}>
		<label class="as-fl">
			<span>{tr('Ime', 'Name')}</span>
			<input class="as-in" name="name" required autocomplete="name" bind:value={name} />
		</label>
		<label class="as-fl">
			<span>{tr('E-adresa', 'Email')}</span>
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
			<span>{tr('Lozinka (najmanje 12 znakova)', 'Password (at least 12 characters)')}</span>
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
		<button class="as-btn" type="submit" disabled={busy}
			>{tr('Napravi račun', 'Create account')}</button
		>
	</form>
</AuthLayout>
