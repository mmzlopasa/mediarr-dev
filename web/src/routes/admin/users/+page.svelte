<script lang="ts">
	import { onMount } from 'svelte';
	import { api, ApiError, type User } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Checkbox from '#lib/design/components/Checkbox.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let users = $state<User[]>([]);
	let name = $state('');
	let email = $state('');
	let password = $state('');
	let isAdmin = $state(false);
	let error = $state('');

	async function refresh() {
		try {
			users = await api.listUsers();
		} catch {
			error = t('admin.users.usersCouldNotBeLoaded');
		}
	}

	onMount(refresh);

	async function create(event: SubmitEvent) {
		event.preventDefault();
		error = '';
		try {
			await api.createUser({ name, email, password, isAdmin });
			name = '';
			email = '';
			password = '';
			isAdmin = false;
			showToast('ok', t('admin.users.theUserWasAdded'));
			await refresh();
		} catch (cause) {
			error = cause instanceof ApiError ? cause.message : t('admin.users.somethingWentWrong');
		}
	}
</script>

<svelte:head><title>{t('admin.users.users')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{t('admin.users.users')}</h1></div>
</div>

{#if error}<Alert kind="err">{error}</Alert>{/if}

<Card title={t('admin.users.newUser')}>
	<form class="form grid-f" onsubmit={create}>
		<Input label={t('common.name2')} required bind:value={name} />
		<Input label={t('common.email')} type="email" required bind:value={email} />
		<Input
			label={t('common.password')}
			hint={t('admin.users.atLeast12Characters')}
			type="password"
			autocomplete="new-password"
			minlength={12}
			required
			bind:value={password}
		/>
		<div class="f">
			<span>{t('admin.users.role')}</span>
			<Checkbox label={t('admin.users.administrator')} bind:checked={isAdmin} />
		</div>
		<div class="btn-row f-full">
			<Button type="submit" variant="gold">{t('admin.users.addUser')}</Button>
		</div>
	</form>
</Card>

<Card title={t('admin.users.allUsers')}>
	<div class="tbl-w">
		<table class="tbl">
			<thead>
				<tr>
					<th>{t('common.name2')}</th>
					<th>{t('common.email')}</th>
					<th>{t('admin.users.role')}</th>
				</tr>
			</thead>
			<tbody>
				{#each users as user (user.id)}
					<tr>
						<td data-l={t('common.name2')}><b>{user.name}</b></td>
						<td data-l={t('common.email')}>{user.email}</td>
						<td data-l={t('admin.users.role')}>
							<Badge kind={user.isAdmin ? 'acc' : 'mute'}>
								{user.isAdmin ? t('admin.users.administrator') : t('common.user')}
							</Badge>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</Card>
