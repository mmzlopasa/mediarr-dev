<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { api, avatarOf, initialsOf, type User } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

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
		showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
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
			showToast('ok', t('common.saved'));
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

<Card id="profile" title={t('profileCard.profile')}>
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
					aria-label={t('profileCard.chooseAProfilePicture')}
				/>
				<Button small disabled={sending} onclick={() => picker?.click()}
					>{sending
						? t('profileCard.sending')
						: avatarOf(user)
							? t('profileCard.changePicture')
							: t('profileCard.addAPicture')}</Button
				>
				{#if avatarOf(user)}
					<Button small variant="danger" onclick={remove}>{t('common.remove')}</Button>
				{/if}
			</div>
		</div>
		<form class="form" onsubmit={save}>
			<Input
				label={t('common.name2')}
				bind:value={name}
				required
				maxlength={200}
				autocomplete="name"
			/>
			<Input
				label={t('profileCard.emailAddress')}
				type="email"
				bind:value={email}
				required
				autocomplete="email"
			/>
			{#if emailChanged}
				<Input
					label={t('profileCard.currentPasswordToChangeThe')}
					type="password"
					bind:value={password}
					required
					autocomplete="current-password"
				/>
			{/if}
			<div class="set-foot">
				<Button type="submit" variant="gold" small disabled={!changed || saving}
					>{t('common.save')}</Button
				>
			</div>
		</form>
	</div>
</Card>
