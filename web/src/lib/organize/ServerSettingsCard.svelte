<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type ServerSettings } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let settings = $state<ServerSettings>();

	onMount(async () => {
		try {
			settings = await api.serverSettings();
		} catch {
			showToast('err', t('common.thisCouldNotBeLoaded'));
		}
	});

	async function save(event: SubmitEvent) {
		event.preventDefault();
		if (!settings) return;
		try {
			settings = await api.setServerSettings(settings);
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
	}
</script>

<Card id="server" title={t('serverSettingsCard.server')}>
	{#if settings}
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{t('serverSettingsCard.qualityAppliesToFilesProcessed')}
			</p>
			<label>
				{t('serverSettingsCard.daysInTheTrash')}
				<input class="in" type="number" min="1" max="3650" bind:value={settings.trashDays} />
			</label>
			<label>
				{t('serverSettingsCard.imageQuality40100')}
				<input class="in" type="number" min="40" max="100" bind:value={settings.imageQuality} />
			</label>
			<label>
				{t('serverSettingsCard.previewSizeInPixels')}
				<input class="in" type="number" min="720" max="4096" bind:value={settings.previewSize} />
			</label>
			<label>
				{t('serverSettingsCard.videoQuality1840Lower')}
				<input class="in" type="number" min="18" max="40" bind:value={settings.videoQuality} />
			</label>
			<label>
				{t('serverSettingsCard.largestVideoHeight')}
				<select class="in" bind:value={settings.videoMaxHeight}>
					<option value={720}>720p</option>
					<option value={1080}>1080p</option>
					<option value={1440}>1440p</option>
					<option value={2160}>2160p</option>
				</select>
			</label>
			<label>
				{t('serverSettingsCard.theServerSName')}
				<input
					class="in"
					maxlength="60"
					placeholder="Mediarr"
					value={settings.serverName ?? ''}
					oninput={(event) => {
						if (settings) settings.serverName = event.currentTarget.value;
					}}
				/>
			</label>
			<label>
				{t('serverSettingsCard.messageOnTheSignIn')}
				<textarea class="in" rows="2" maxlength="1000" bind:value={settings.loginMessage}
				></textarea>
			</label>
			<label>
				<input type="checkbox" bind:checked={settings.passwordLogin} />
				{t('serverSettingsCard.allowSigningInWithA')}
			</label>
			<label>
				<input
					type="checkbox"
					checked={settings.visibleOnNetwork ?? true}
					onchange={(event) => {
						if (settings) settings.visibleOnNetwork = event.currentTarget.checked;
					}}
				/>
				{t('serverSettingsCard.appsOnTheSameNetwork')}
			</label>
			<label>
				<input
					type="checkbox"
					checked={settings.dlnaServer ?? false}
					onchange={(event) => {
						if (settings) settings.dlnaServer = event.currentTarget.checked;
					}}
				/>
				{t('admin.dlnaServer')}
			</label>
			<p class="alb-meta">
				{t('admin.dlnaServerHint')}
				{#if settings.dlnaServer && settings.dlnaOwner}
					{t('admin.dlnaOwner', { name: settings.dlnaOwner })}
					{settings.dlnaAnnounced ? t('admin.dlnaAnnounced') : t('admin.dlnaNotAnnounced')}
				{/if}
			</p>
			<label>
				<input type="checkbox" bind:checked={settings.maintenance} />
				{t('serverSettingsCard.maintenanceModeOnlyAdministratorsCan')}
			</label>
			<label>
				{t('serverSettingsCard.howSureAFaceMust')}
				<input
					class="in"
					type="number"
					min="0.1"
					max="1"
					step="0.05"
					bind:value={settings.faceMinScore}
				/>
			</label>
			<label>
				{t('serverSettingsCard.howAlikeFacesMustBe')}
				<input
					class="in"
					type="number"
					min="0.1"
					max="2"
					step="0.05"
					bind:value={settings.faceMaxDistance}
				/>
			</label>
			<label>
				{t('serverSettingsCard.scanTheExternalLibraryEvery')}
				<input class="in" type="number" min="1" max="720" bind:value={settings.externalScanHours} />
			</label>
			<p class="alb-meta">
				{t('serverSettingsCard.theNumberOfJobsApplies')}
			</p>
			<label>
				{t('serverSettingsCard.backgroundJobs0UsesThe')}
				<input class="in" type="number" min="0" max="64" bind:value={settings.workerConcurrency} />
			</label>
			<label>
				{t('serverSettingsCard.videosAtATime')}
				<input class="in" type="number" min="1" max="16" bind:value={settings.videoWorkers} />
			</label>
			<label>
				{t('serverSettingsCard.analysesAtATime')}
				<input class="in" type="number" min="1" max="16" bind:value={settings.analysisWorkers} />
			</label>
			<p class="alb-meta">
				{t('serverSettingsCard.ifYouLockYourselfOut')}
			</p>
			<div><Button type="submit" variant="gold" small>{t('common.save')}</Button></div>
		</form>
	{:else}
		<Skeleton height="200px" />
	{/if}
</Card>
