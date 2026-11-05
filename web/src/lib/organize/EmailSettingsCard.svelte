<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type EmailSettings } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let settings = $state<EmailSettings>();
	let password = $state('');

	onMount(async () => {
		try {
			settings = await api.emailSettings();
		} catch {
			showToast('err', tr('Podaci se ne mogu učitati.', 'This could not be loaded.'));
		}
	});

	async function save(event: SubmitEvent) {
		event.preventDefault();
		if (!settings) return;
		try {
			settings = await api.setEmailSettings({
				enabled: settings.enabled,
				host: settings.host,
				port: settings.port,
				username: settings.username,
				from: settings.from,
				security: settings.security,
				publicUrl: settings.publicUrl,
				password: password || undefined
			});
			password = '';
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		}
	}

	async function test() {
		try {
			await api.sendTestEmail();
			showToast('ok', tr('Poruka je poslana.', 'The message was sent.'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : tr('Nije poslano.', 'Not sent.'));
		}
	}
</script>

<Card title={tr('E-pošta', 'Email')}>
	{#if settings}
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{tr(
					'Mediarr šalje poruke preko vašeg SMTP servera: poziv u album i poveznicu za novu lozinku.',
					'Mediarr sends through your own SMTP server: album invitations and links for a new password.'
				)}
			</p>
			<label>
				<input type="checkbox" bind:checked={settings.enabled} />
				{tr('Šalji e-poštu', 'Send email')}
			</label>
			<label>
				{tr('SMTP server', 'SMTP server')}
				<input class="in" bind:value={settings.host} autocomplete="off" />
			</label>
			<label>
				{tr('Port', 'Port')}
				<input class="in" type="number" min="1" max="65535" bind:value={settings.port} />
			</label>
			<label>
				{tr('Zaštita veze', 'Connection security')}
				<select class="in" bind:value={settings.security}>
					<option value="starttls">STARTTLS</option>
					<option value="tls">TLS</option>
					<option value="none">{tr('Bez zaštite', 'None')}</option>
				</select>
			</label>
			<label>
				{tr('Korisničko ime', 'Username')}
				<input class="in" bind:value={settings.username} autocomplete="off" />
			</label>
			<label>
				{settings.hasPassword
					? tr(
							'SMTP lozinka (prazno zadržava postojeću)',
							'SMTP password (empty keeps the saved one)'
						)
					: tr('SMTP lozinka', 'SMTP password')}
				<input class="in" type="password" bind:value={password} autocomplete="new-password" />
			</label>
			<label>
				{tr('Adresa pošiljatelja', "Sender's address")}
				<input class="in" type="email" bind:value={settings.from} />
			</label>
			<label>
				{tr('Adresa ovog servera', 'Address of this server')}
				<input
					class="in"
					placeholder="https://photos.example.com"
					bind:value={settings.publicUrl}
				/>
			</label>
			<p class="alb-meta">
				{tr(
					'Bez adrese servera poveznica za novu lozinku se ne šalje.',
					'Without the address of this server, no link for a new password is sent.'
				)}
			</p>
			<div class="btn-row">
				<Button type="submit" variant="gold" small>{tr('Spremi', 'Save')}</Button>
				<Button small onclick={test}>{tr('Pošalji probnu poruku', 'Send a test message')}</Button>
			</div>
		</form>
	{:else}
		<Skeleton height="200px" />
	{/if}
</Card>
