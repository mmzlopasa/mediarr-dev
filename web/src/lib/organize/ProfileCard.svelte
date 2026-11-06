<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { api, avatarOf, initialsOf, type User } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	/** One's own name, email address and picture. */
	let { user }: { user: User } = $props();

	// The form starts from the account, and follows it after a save.
	let name = $state('');
	let email = $state('');
	let password = $state('');
	let saving = $state(false);
	let sending = $state(false);
	let picker = $state<HTMLInputElement>();

	$effect.pre(() => {
		name = user.name;
		email = user.email;
	});

	const emailChanged = $derived(email.trim().toLowerCase() !== user.email);
	const changed = $derived(name.trim() !== user.name || emailChanged);

	function fail(cause: unknown) {
		showToast(
			'err',
			cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
		);
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		saving = true;
		try {
			await api.updateProfile({
				name: name.trim(),
				...(emailChanged ? { email: email.trim(), currentPassword: password } : {})
			});
			password = '';
			await invalidate('app:session');
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			fail(cause);
		} finally {
			saving = false;
		}
	}

	async function choose(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		const file = input.files?.[0];
		input.value = '';
		if (!file) return;
		sending = true;
		try {
			await api.setAvatar(file);
			await invalidate('app:session');
		} catch (cause) {
			fail(cause);
		} finally {
			sending = false;
		}
	}

	async function remove() {
		try {
			await api.removeAvatar();
			await invalidate('app:session');
		} catch (cause) {
			fail(cause);
		}
	}
</script>

<Card id="profile" title={tr('Profil', 'Profile')}>
	<div class="prof">
		<div class="prof-pic">
			<span class="prof-av" aria-hidden="true">
				{#if avatarOf(user)}<img src={avatarOf(user)} alt="" />{:else}{initialsOf(user.name)}{/if}
			</span>
			<div class="prof-pic-acts">
				<input
					bind:this={picker}
					type="file"
					accept="image/*"
					class="sr"
					onchange={choose}
					aria-label={tr('Odaberite sliku profila', 'Choose a profile picture')}
				/>
				<Button small disabled={sending} onclick={() => picker?.click()}
					>{sending
						? tr('Šaljem…', 'Sending…')
						: avatarOf(user)
							? tr('Promijeni sliku', 'Change picture')
							: tr('Dodaj sliku', 'Add a picture')}</Button
				>
				{#if avatarOf(user)}
					<Button small variant="danger" onclick={remove}>{tr('Ukloni', 'Remove')}</Button>
				{/if}
			</div>
		</div>
		<form class="form" onsubmit={save}>
			<Input
				label={tr('Ime', 'Name')}
				bind:value={name}
				required
				maxlength={200}
				autocomplete="name"
			/>
			<Input
				label={tr('E-mail adresa', 'Email address')}
				type="email"
				bind:value={email}
				required
				autocomplete="email"
			/>
			{#if emailChanged}
				<Input
					label={tr(
						'Trenutna lozinka, za promjenu e-maila',
						'Current password, to change the email'
					)}
					type="password"
					bind:value={password}
					required
					autocomplete="current-password"
				/>
			{/if}
			<div class="set-foot">
				<Button type="submit" variant="gold" small disabled={!changed || saving}
					>{tr('Spremi', 'Save')}</Button
				>
			</div>
		</form>
	</div>
</Card>
