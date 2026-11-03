<script lang="ts">
	import { api, type Album, type MemberRole, type UserRef } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let {
		album,
		open = $bindable(false),
		onChanged
	}: { album: Album; open?: boolean; onChanged: () => void } = $props();

	let users = $state<UserRef[]>([]);
	let userId = $state('');
	let role = $state<MemberRole>('viewer');

	const roles = $derived([
		{ value: 'viewer', label: tr('Gledatelj', 'Viewer') },
		{ value: 'contributor', label: tr('Suradnik', 'Contributor') },
		{ value: 'editor', label: tr('Urednik', 'Editor') }
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
				.catch(() =>
					showToast('err', tr('Korisnici se nisu učitali.', 'Users could not be loaded.'))
				);
		}
	});

	async function run(action: () => Promise<void>) {
		try {
			await action();
			onChanged();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	const add = () =>
		run(async () => {
			await api.setMember(album.id, userId, role);
			userId = '';
		});
</script>

<Dialog title={tr('Dijeli s korisnicima', 'Share with users')} bind:open>
	{#each members as member (member.userId)}
		<div class="alb-list">
			<b>{member.name}</b>
			<select
				class="in"
				aria-label={tr('Uloga', 'Role')}
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
				>{tr('Ukloni', 'Remove')}</Button
			>
		</div>
	{:else}
		<p class="alb-meta">{tr('Album još nije podijeljen.', 'This album is not shared yet.')}</p>
	{/each}
	{#if free.length > 0}
		<div class="form">
			<Select
				label={tr('Korisnik', 'User')}
				bind:value={userId}
				options={[
					{ value: '', label: tr('Odaberi', 'Choose') },
					...free.map((user) => ({ value: user.id, label: user.name }))
				]}
			/>
			<Select label={tr('Uloga', 'Role')} bind:value={role} options={roles} />
			<Button small variant="gold" disabled={!userId} onclick={add}>{tr('Dodaj', 'Add')}</Button>
		</div>
	{:else if users.length === 0}
		<p class="alb-meta">
			{tr('Na ovom serveru nema drugih korisnika.', 'There are no other users on this server.')}
		</p>
	{/if}
</Dialog>
