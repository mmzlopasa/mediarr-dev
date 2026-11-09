<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type EmailSettings } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let settings = $state<EmailSettings>();
	let password = $state('');

	onMount(async () => {
		try {
			settings = await api.emailSettings();
		} catch {
			showToast('err', t('common.thisCouldNotBeLoaded'));
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
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
	}

	async function test() {
		try {
			await api.sendTestEmail();
			showToast('ok', t('emailSettingsCard.theMessageWasSent'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('emailSettingsCard.notSent'));
		}
	}
</script>

<Card id="email" title={t('emailSettingsCard.email')}>
	{#if settings}
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{t('emailSettingsCard.mediarrSendsThroughYourOwn')}
			</p>
			<label>
				<input type="checkbox" bind:checked={settings.enabled} />
				{t('emailSettingsCard.sendEmail')}
			</label>
			<label>
				{t('emailSettingsCard.smtpServer')}
				<input class="in" bind:value={settings.host} autocomplete="off" />
			</label>
			<label>
				{t('emailSettingsCard.port')}
				<input class="in" type="number" min="1" max="65535" bind:value={settings.port} />
			</label>
			<label>
				{t('emailSettingsCard.connectionSecurity')}
				<select class="in" bind:value={settings.security}>
					<option value="starttls">STARTTLS</option>
					<option value="tls">TLS</option>
					<option value="none">{t('emailSettingsCard.none')}</option>
				</select>
			</label>
			<label>
				{t('emailSettingsCard.username')}
				<input class="in" bind:value={settings.username} autocomplete="off" />
			</label>
			<label>
				{settings.hasPassword
					? t('emailSettingsCard.smtpPasswordEmptyKeepsThe')
					: t('emailSettingsCard.smtpPassword')}
				<input class="in" type="password" bind:value={password} autocomplete="new-password" />
			</label>
			<label>
				{t('emailSettingsCard.senderSAddress')}
				<input class="in" type="email" bind:value={settings.from} />
			</label>
			<label>
				{t('emailSettingsCard.addressOfThisServer')}
				<input
					class="in"
					placeholder="https://photos.example.com"
					bind:value={settings.publicUrl}
				/>
			</label>
			<p class="alb-meta">
				{t('emailSettingsCard.withoutTheAddressOfThis')}
			</p>
			<div class="btn-row">
				<Button type="submit" variant="gold" small>{t('common.save')}</Button>
				<Button small onclick={test}>{t('emailSettingsCard.sendATestMessage')}</Button>
			</div>
		</form>
	{:else}
		<Skeleton height="200px" />
	{/if}
</Card>
