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
	import { tr } from '#lib/i18n.svelte.ts';

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
			error = tr('Korisnici se nisu učitali.', 'Users could not be loaded.');
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
			showToast('ok', tr('Korisnik je dodan.', 'The user was added.'));
			await refresh();
		} catch (cause) {
			error = cause instanceof ApiError ? cause.message : tr('Greška.', 'Something went wrong.');
		}
	}
</script>

<svelte:head><title>{tr('Korisnici', 'Users')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div><h1>{tr('Korisnici', 'Users')}</h1></div>
</div>

{#if error}<Alert kind="err">{error}</Alert>{/if}

<Card title={tr('Novi korisnik', 'New user')}>
	<form class="form grid-f" onsubmit={create}>
		<Input label={tr('Ime', 'Name')} required bind:value={name} />
		<Input label={tr('E-adresa', 'Email')} type="email" required bind:value={email} />
		<Input
			label={tr('Lozinka', 'Password')}
			hint={tr('Najmanje 12 znakova.', 'At least 12 characters.')}
			type="password"
			autocomplete="new-password"
			minlength={12}
			required
			bind:value={password}
		/>
		<div class="f">
			<span>{tr('Uloga', 'Role')}</span>
			<Checkbox label={tr('Administrator', 'Administrator')} bind:checked={isAdmin} />
		</div>
		<div class="btn-row f-full">
			<Button type="submit" variant="gold">{tr('Dodaj korisnika', 'Add user')}</Button>
		</div>
	</form>
</Card>

<Card title={tr('Svi korisnici', 'All users')}>
	<div class="tbl-w">
		<table class="tbl">
			<thead>
				<tr>
					<th>{tr('Ime', 'Name')}</th>
					<th>{tr('E-adresa', 'Email')}</th>
					<th>{tr('Uloga', 'Role')}</th>
				</tr>
			</thead>
			<tbody>
				{#each users as user (user.id)}
					<tr>
						<td data-l={tr('Ime', 'Name')}><b>{user.name}</b></td>
						<td data-l={tr('E-adresa', 'Email')}>{user.email}</td>
						<td data-l={tr('Uloga', 'Role')}>
							<Badge kind={user.isAdmin ? 'acc' : 'mute'}>
								{user.isAdmin ? tr('Administrator', 'Administrator') : tr('Korisnik', 'User')}
							</Badge>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</Card>
