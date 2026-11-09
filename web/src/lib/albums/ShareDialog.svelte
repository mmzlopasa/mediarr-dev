<script lang="ts">
	import { api, type Album, type MemberRole, type UserRef } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let {
		album,
		open = $bindable(false),
		onChanged
	}: { album: Album; open?: boolean; onChanged: () => void } = $props();

	let users = $state<UserRef[]>([]);
	let userId = $state('');
	let role = $state<MemberRole>('viewer');

	const roles = $derived([
		{ value: 'viewer', label: t('shareDialog.viewer') },
		{ value: 'contributor', label: t('shareDialog.contributor') },
		{ value: 'editor', label: t('shareDialog.editor') }
	]);
	const members = $derived(album.members ?? []);
	const free = $derived(
		users.filter((user) => !members.some((member) => member.userId === user.id))
	);

	$effect(() => {
		if (open) {
			api
				.directory()
				.then((list) => (users = list))
				.catch(() => showToast('err', t('shareDialog.usersCouldNotBeLoaded')));
		}
	});

	async function run(action: () => Promise<void>) {
		try {
			await action();
			onChanged();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	const add = () =>
		run(async () => {
			await api.setMember(album.id, userId, role);
			userId = '';
		});
</script>

<Dialog title={t('shareDialog.shareWithUsers')} bind:open>
	{#each members as member (member.userId)}
		<div class="alb-list">
			<b>{member.name}</b>
			<select
				class="in"
				aria-label={t('shareDialog.role')}
				value={member.role}
				onchange={(event) =>
					run(() =>
						api.setMember(album.id, member.userId, event.currentTarget.value as MemberRole)
					)}
			>
				{#each roles as option (option.value)}
					<option value={option.value}>{option.label}</option>
				{/each}
			</select>
			<Button small onclick={() => run(() => api.removeMember(album.id, member.userId))}
				>{t('common.remove')}</Button
			>
		</div>
	{:else}
		<p class="alb-meta">{t('shareDialog.thisAlbumIsNotShared')}</p>
	{/each}
	{#if free.length > 0}
		<div class="form">
			<Select
				label={t('common.user')}
				bind:value={userId}
				options={[
					{ value: '', label: t('shareDialog.choose') },
					...free.map((user) => ({ value: user.id, label: user.name }))
				]}
			/>
			<Select label={t('shareDialog.role')} bind:value={role} options={roles} />
			<Button small variant="gold" disabled={!userId} onclick={add}>{t('common.add')}</Button>
		</div>
	{:else if users.length === 0}
		<p class="alb-meta">
			{t('shareDialog.thereAreNoOtherUsers')}
		</p>
	{/if}
</Dialog>
