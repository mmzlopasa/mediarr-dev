<script lang="ts">
	import ServerSettingsCard from '#lib/organize/ServerSettingsCard.svelte';
	import EmailSettingsCard from '#lib/organize/EmailSettingsCard.svelte';
	import KeepCard from '#lib/organize/KeepCard.svelte';
	import { onMount } from 'svelte';
	import {
		api,
		type AnalysisProgress,
		type ExternalLibrary,
		type OIDCSettings,
		type User,
		type ImportCreate,
		type ImportEntry,
		type ImportDetail,
		type BackupRun,
		type BackupSettings,
		type Features,
		type Webhook,
		type AISettings
	} from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import SectionNav from '#lib/design/components/SectionNav.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { dateLocale, t, k, type Key } from '#lib/i18n.svelte.ts';

	let light = $state('');
	let dark = $state('');
	let loaded = $state(false);
	let failed = $state(false);
	let analysis = $state<AnalysisProgress>();
	let external = $state<ExternalLibrary>();
	let users = $state<User[]>([]);
	let owner = $state('');

	onMount(async () => {
		try {
			const style = await api.mapStyle();
			light = style.light;
			dark = style.dark;
			analysis = await api.analysisProgress();
			external = await api.externalLibrary();
			owner = external.ownerId ?? '';
			users = await api.listUsers();
			loaded = true;
		} catch {
			failed = true;
		}
	});

	let oidc = $state<OIDCSettings>();
	let oidcSecret = $state('');

	onMount(async () => {
		try {
			oidc = await api.oidcSettings();
		} catch {
			oidc = undefined;
		}
	});

	async function saveOIDC(event: SubmitEvent) {
		event.preventDefault();
		if (!oidc) return;
		try {
			oidc = await api.setOIDCSettings({
				issuer: oidc.issuer,
				clientId: oidc.clientId,
				label: oidc.label,
				autoCreate: oidc.autoCreate,
				linkAdmins: oidc.linkAdmins,
				secret: oidcSecret || undefined
			});
			oidcSecret = '';
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	let imports = $state<ImportEntry[]>([]);
	// The report of an import, with each file that did not come in, opened on request.
	let importReports = $state<Record<string, ImportDetail>>({});
	async function toggleImportReport(id: string) {
		if (importReports[id]) {
			importReports = Object.fromEntries(
				Object.entries(importReports).filter(([key]) => key !== id)
			);
			return;
		}
		importReports = { ...importReports, [id]: await api.importDetail(id) };
	}
	let importSource = $state<ImportCreate['source']>('immich');
	let importOwner = $state('');
	let importAddress = $state('');
	let importKey = $state('');
	let importFolder = $state('');
	let importTimer: ReturnType<typeof setInterval> | undefined;

	async function loadImports() {
		imports = await api.imports().catch(() => imports);
	}

	onMount(() => {
		loadImports();
		importTimer = setInterval(loadImports, 5000);
		return () => clearInterval(importTimer);
	});

	async function startImport(event: SubmitEvent) {
		event.preventDefault();
		try {
			await api.startImport({
				source: importSource,
				ownerId: importOwner,
				...(importSource === 'immich'
					? { address: importAddress, apiKey: importKey }
					: { folder: importFolder })
			});
			importKey = '';
			await loadImports();
			showToast('ok', t('admin.settings.theImportHasStarted'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	const FEATURE_LABELS: Record<string, { label: Key }> = {
		backup: { label: k('admin.settings.scheduledBackup') },
		filters: { label: k('admin.settings.filtersInTheEditor') },
		documents: { label: k('admin.settings.documentsAlbum') },
		family: { label: k('admin.settings.familyLibrary') },
		webhooks: { label: k('admin.settings.webhooks') },
		kiosk: { label: k('admin.settings.kioskForTvAndTablet') },
		descriptions: { label: k('admin.settings.aiDescriptionsAndChatSearch') }
	};
	let features = $state<Features>({});
	let backup = $state<BackupSettings>();
	let backupRuns = $state<BackupRun[]>([]);
	// The latest runs say how backup is doing; older ones are one click away.
	const FIRST_RUNS = 6;
	let allRuns = $state(false);
	let backupPassword = $state('');
	let backupKey = $state('');
	let backupSecret = $state('');
	let backupHour = $state('3');

	async function loadBackup() {
		backupRuns = await api.backupRuns().catch(() => backupRuns);
	}

	onMount(() => {
		api
			.features()
			.then((value) => (features = value))
			.catch(() => undefined);
		api
			.backupSettings()
			.then((value) => {
				backup = value;
				backupHour = String(value.hour);
			})
			.catch(() => undefined);
		loadBackup();
		const timer = setInterval(loadBackup, 5000);
		return () => clearInterval(timer);
	});

	async function toggleFeature(name: string, enabled: boolean) {
		try {
			await api.setFeature(name, enabled);
			features = { ...features, [name]: enabled };
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function saveBackup(event: SubmitEvent) {
		event.preventDefault();
		if (!backup) return;
		try {
			backup = await api.setBackupSettings({
				repository: backup.repository,
				hour: Number(backupHour),
				password: backupPassword || undefined,
				s3Key: backupKey || undefined,
				s3Secret: backupSecret || undefined
			});
			backupPassword = backupKey = backupSecret = '';
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	async function runBackup(kind: BackupRun['kind']) {
		try {
			await api.startBackupRun(kind);
			await loadBackup();
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	let webhooks = $state<Webhook[]>([]);
	let hookUrl = $state('');
	let hookEvents = $state<Webhook['events']>(['asset.ready']);
	let hookSecret = $state('');

	async function loadHooks() {
		webhooks = await api.webhooks().catch(() => webhooks);
	}

	onMount(loadHooks);

	async function addHook(event: SubmitEvent) {
		event.preventDefault();
		try {
			const made = await api.createWebhook(hookUrl, hookEvents);
			hookSecret = made.secret;
			hookUrl = '';
			await loadHooks();
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	async function hookAction(action: () => Promise<void>) {
		try {
			await action();
			await loadHooks();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	let familyIds = $state<string[]>([]);

	onMount(async () => {
		familyIds = (await api.familyMembers().catch(() => [])).map((member) => member.id);
	});

	async function toggleFamily(id: string, member: boolean) {
		try {
			await api.setFamilyMember(id, member);
			familyIds = member ? [...familyIds, id] : familyIds.filter((other) => other !== id);
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	let ai = $state<AISettings>();

	async function loadAI() {
		ai = await api.aiSettings().catch(() => ai);
	}

	onMount(() => {
		loadAI();
		const timer = setInterval(loadAI, 15000);
		return () => clearInterval(timer);
	});

	async function saveAI(event: SubmitEvent) {
		event.preventDefault();
		if (!ai) return;
		try {
			ai = await api.setAISettings(ai.address, ai.visionModel, ai.textModel);
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	async function externalAction(action: () => Promise<unknown>) {
		try {
			await action();
			external = await api.externalLibrary();
			showToast('ok', t('admin.settings.theScanHasStarted'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	const sections = $derived(
		[
			{ id: 'analysis', label: t('admin.settings.searchAndFaces') },
			{ id: 'external', label: t('admin.settings.externalLibrary') },
			oidc && { id: 'sso', label: t('admin.settings.singleSignOn') },
			{ id: 'import', label: t('common.import') },
			{ id: 'additions', label: t('admin.settings.additions') },
			backup && { id: 'backup', label: 'Backup' },
			{ id: 'keep', label: t('admin.settings.aCopyAtARelative') },
			features.family && { id: 'family', label: t('admin.settings.family') },
			features.descriptions && ai && { id: 'ai', label: t('admin.settings.aiDescriptions') },
			features.webhooks && { id: 'webhooks', label: 'Webhooks' },
			{ id: 'server', label: 'Server' },
			{ id: 'email', label: t('admin.settings.email') },
			{ id: 'map', label: t('admin.settings.map') }
		].filter((item): item is { id: string; label: string } => Boolean(item))
	);

	const STATUS: Record<string, { label: Key; tone: string }> = {
		running: { label: k('account.import.running'), tone: 'run' },
		uploading: { label: k('account.import.waitingForFiles'), tone: '' },
		queued: { label: k('admin.settings.waiting'), tone: '' },
		done: { label: k('qRSignInDialog.done'), tone: 'ok' },
		failed: { label: k('admin.jobs.failed'), tone: 'err' },
		cancelled: { label: k('account.import.stopped'), tone: '' }
	};
	const status = (value: string) => STATUS[value] ?? { hr: value, en: value, tone: '' };

	async function save(event: SubmitEvent) {
		event.preventDefault();
		try {
			const style = await api.setMapStyle({ light, dark });
			light = style.light;
			dark = style.dark;
			showToast('ok', t('common.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t('admin.settings.settings')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t('admin.settings.settings')}</h1></div></div>

{#if failed}
	<Alert kind="err">{t('admin.settings.theSettingsCouldNotBe')}</Alert>
{:else if !loaded}
	<Skeleton height="200px" />
{:else}
	<div class="set">
		<SectionNav items={sections} />
		<div class="set-body">
			<Card id="analysis" title={t('admin.settings.smartSearchAndFaces')}>
				{#if analysis?.enabled}
					<Kv label={t('admin.settings.analysed')} value="{analysis.analyzed} / {analysis.total}" />
					<Bar
						pct={analysis.total ? Math.round((analysis.analyzed / analysis.total) * 100) : 0}
						label={t('admin.settings.pictureAnalysis')}
						progress
					/>
				{:else}
					<p class="alb-meta">
						{t('admin.settings.notTurnedOnInEnv')}
					</p>
				{/if}
			</Card>
			<Card id="external" title={t('admin.settings.externalLibrary')}>
				{#if !external?.available}
					<p class="alb-meta">
						{t('admin.settings.notTurnedOnInEnv2')}
					</p>
				{:else}
					<p class="alb-meta">
						{t('admin.settings.mediarrOnlyReadsThisFolder')}
					</p>
					<label class="f set-solo">
						<span>{t('admin.settings.whosePhotosTheseAre')}</span>
						<select class="in" bind:value={owner} disabled={(external?.assets ?? 0) > 0}>
							<option value="" disabled>{t('admin.settings.chooseAUser')}</option>
							{#each users as user (user.id)}
								<option value={user.id}>{user.name} ({user.email})</option>
							{/each}
						</select>
					</label>
					{#if external.ownerId}
						<Kv label={t('admin.settings.photosAndVideos')} value={String(external.assets)} />
						<Kv label={t('admin.settings.unavailable')} value={String(external.missing)} />
						<Kv
							label={t('admin.settings.state')}
							value={external.scanning
								? t('admin.settings.scanning')
								: external.scanFinishedAt
									? t('admin.settings.scanned') +
										new Date(external.scanFinishedAt).toLocaleString(dateLocale())
									: t('admin.settings.notScannedYet')}
						/>
						{#if external.scanError}<Alert kind="err">{external.scanError}</Alert>{/if}
					{/if}
					{#if !external.ownerId}
						<Button
							variant="gold"
							small
							disabled={!owner}
							onclick={() => externalAction(() => api.setExternalOwner(owner))}
							>{t('admin.settings.saveAndScan')}</Button
						>
					{:else}
						<Button small onclick={() => externalAction(api.scanExternal)}
							>{t('admin.settings.scanNow')}</Button
						>
					{/if}
				{/if}
			</Card>
			{#if oidc}
				<Card id="sso" title={t('admin.settings.singleSignOnOidc')}>
					<form class="form" onsubmit={saveOIDC}>
						<p class="alb-meta">
							{t('admin.settings.optionalAnEmptyIssuerTurns')}
							<code>{location.origin}/api/auth/oidc/callback</code>
						</p>
						<Input label={t('admin.settings.issuer')} bind:value={oidc.issuer} />
						<Input label="Client ID" bind:value={oidc.clientId} />
						<Input
							label={oidc.hasSecret ? t('admin.settings.clientSecretSavedTypeTo') : 'Client secret'}
							bind:value={oidcSecret}
						/>
						<Input label={t('admin.settings.buttonLabel')} bind:value={oidc.label} />
						<label>
							<input type="checkbox" bind:checked={oidc.autoCreate} />
							{t('admin.settings.createAnAccountForSomeone')}
						</label>
						<label>
							<input type="checkbox" bind:checked={oidc.linkAdmins} />
							{t('admin.settings.alsoLinkAdministratorsByEmail')}
						</label>
						<Button type="submit" variant="gold" small>{t('common.save')}</Button>
					</form>
				</Card>
			{/if}
			<Card id="import" title={t('common.import')}>
				<form class="form" onsubmit={startImport}>
					<p class="alb-meta">
						{t('admin.settings.aFileThatIsAlready')}
					</p>
					<label class="f">
						<span>{t('admin.settings.from')}</span>
						<select class="in" bind:value={importSource} data-testid="import-source">
							<option value="immich">Immich</option>
							<option value="takeout">Google Takeout</option>
							<option value="icloud">iCloud</option>
						</select>
					</label>
					<label class="f">
						<span>{t('admin.settings.intoWhoseLibrary')}</span>
						<select class="in" bind:value={importOwner} required data-testid="import-owner">
							<option value="" disabled>{t('admin.settings.chooseAUser')}</option>
							{#each users as user (user.id)}
								<option value={user.id}>{user.name} ({user.email})</option>
							{/each}
						</select>
					</label>
					{#if importSource === 'immich'}
						<Input label={t('admin.settings.immichAddress')} bind:value={importAddress} />
						<Input label={t('admin.settings.immichApiKey')} bind:value={importKey} />
						<p class="alb-meta">
							{t('admin.settings.theKeyIsErasedWhen')}
						</p>
					{:else}
						<Input
							label={t('admin.settings.folderInsideTheExternalLibrary')}
							bind:value={importFolder}
						/>
						<p class="alb-meta">
							{t('admin.settings.unpackTheExportIntoThe')}
						</p>
					{/if}
					<Button type="submit" variant="gold" small>{t('admin.settings.startTheImport')}</Button>
				</form>
				{#if imports.length}
					<h3 class="set-sub">{t('admin.settings.imports')}</h3>
				{/if}
				<ul class="set-list">
					{#each imports as entry (entry.id)}
						<li data-import={entry.source}>
							<span class="set-list-t">
								<b>{entry.source}{entry.fromZip ? ' · ZIP' : ''} → {entry.userEmail}</b>
								<small>
									<em class="set-chip {status(entry.status).tone}"
										>{t(status(entry.status).label)}</em
									>
									{t('admin.settings.added')}
									{entry.added} · {t('admin.settings.skipped')}
									{entry.skipped} · {t('admin.settings.failed')}
									{entry.failed}{#if entry.total}
										· {entry.added + entry.skipped + entry.failed} / {entry.total}{/if}
								</small>
								{#if importReports[entry.id]}
									<div class="imp-report">
										{#if importReports[entry.id].problems.length === 0}
											<p>{t('admin.settings.noFilesFailed')}</p>
										{:else}
											<ul>
												{#each importReports[entry.id].problems as problem, n (n)}
													<li><b class="mono">{problem.name}</b> {problem.reason}</li>
												{/each}
											</ul>
										{/if}
									</div>
								{/if}
								{#if entry.lastError}
									<button
										type="button"
										class="set-clamp"
										title={entry.lastError}
										onclick={(event) => event.currentTarget.classList.toggle('open')}
										>{entry.lastError}</button
									>
								{/if}
							</span>
							<span class="imp-acts">
								{#if entry.status === 'running' || entry.status === 'uploading'}
									<Button
										small
										onclick={async () => {
											await api.cancelImport(entry.id);
											await loadImports();
										}}>{t('common.stop')}</Button
									>
								{/if}
								{#if entry.failed > 0}
									<Button small onclick={() => toggleImportReport(entry.id)}
										>{importReports[entry.id]
											? t('common.hide')
											: t('admin.settings.report')}</Button
									>
								{/if}
								{#if entry.status !== 'running'}
									<Button
										small
										variant="danger"
										onclick={async () => {
											await api.removeImport(entry.id);
											await loadImports();
										}}>{t('common.remove')}</Button
									>
								{/if}
							</span>
						</li>
					{/each}
				</ul>
			</Card>
			<Card id="additions" title={t('admin.settings.additions')}>
				<p class="alb-meta">
					{t('admin.settings.eachIsOffUntilYou')}
				</p>
				{#each Object.keys(FEATURE_LABELS) as name (name)}
					<label class="set-row">
						<span>{t(FEATURE_LABELS[name].label)}</span>
						<input
							type="checkbox"
							class="switch"
							data-feature={name}
							checked={features[name] ?? false}
							onchange={(event) => toggleFeature(name, event.currentTarget.checked)}
						/>
					</label>
				{/each}
			</Card>
			{#if backup}
				<Card id="backup" title="Backup">
					{#snippet actions()}
						<Button small onclick={() => runBackup('backup')}
							>{t('admin.settings.backUpNow')}</Button
						>
						<Button small onclick={() => runBackup('restore_test')}
							>{t('admin.settings.testBringingItBack')}</Button
						>
					{/snippet}
					<form class="form" onsubmit={saveBackup}>
						<p class="alb-meta">
							{t('admin.settings.originalsAndTheDatabaseEncrypted', {
								localFolder: backup.localFolder
							})}
						</p>
						<Alert kind="warn">{t('admin.settings.writeThePasswordDownSomewhere')}</Alert>
						<Input label={t('admin.settings.destination')} bind:value={backup.repository} />
						<Input
							label={backup.hasPassword
								? t('admin.settings.passwordSavedTypeToChange')
								: t('admin.settings.backupPassword')}
							bind:value={backupPassword}
						/>
						<Input
							label={backup.hasS3Key
								? t('admin.settings.accessKeySaved')
								: t('admin.settings.accessKeyS3B2')}
							bind:value={backupKey}
						/>
						<Input label={t('admin.settings.secretKeyS3B2')} bind:value={backupSecret} />
						<Input label={t('admin.settings.hourOfTheDay0')} bind:value={backupHour} />
						<Button data-testid="backup-save" type="submit" variant="gold" small
							>{t('common.save')}</Button
						>
					</form>
					{#if backupRuns.length}
						<h3 class="set-sub">{t('admin.settings.history')}</h3>
						<ul class="set-list">
							{#each allRuns ? backupRuns : backupRuns.slice(0, FIRST_RUNS) as run (run.id)}
								<li data-backup-run={run.kind}>
									<span class="set-list-t">
										<b
											>{run.kind === 'backup'
												? 'Backup'
												: t('admin.settings.restoreTest')}{run.destinationName
												? ` → ${run.destinationName}`
												: ''}</b
										>
										<small>
											<em class="set-chip {status(run.status).tone}"
												>{t(status(run.status).label)}</em
											>
											<time datetime={run.startedAt}
												>{new Date(run.startedAt).toLocaleString(dateLocale())}</time
											>
											· {t('admin.settings.files')}
											{run.files}
										</small>
										{#if run.message}
											<button
												type="button"
												class="set-clamp"
												title={run.message}
												onclick={(event) => event.currentTarget.classList.toggle('open')}
												>{run.message}</button
											>
										{/if}
									</span>
								</li>
							{/each}
						</ul>
						{#if backupRuns.length > FIRST_RUNS}
							<button type="button" class="set-more" onclick={() => (allRuns = !allRuns)}>
								{allRuns
									? t('admin.settings.showFewer')
									: t('admin.settings.showAllBackuprunscount', {
											backupRunsCount: backupRuns.length
										})}
							</button>
						{/if}
					{/if}
				</Card>
			{/if}
			<KeepCard onChange={loadBackup} />
			{#if features.family}
				<Card id="family" title={t('admin.settings.familyLibrary')}>
					<p class="alb-meta">
						{t('admin.settings.membersSharePhotosByRules')}
					</p>
					{#each users as user (user.id)}
						<label class="set-row">
							<span>{user.name} <small>{user.email}</small></span>
							<input
								type="checkbox"
								class="switch"
								data-family={user.email}
								checked={familyIds.includes(user.id)}
								onchange={(event) => toggleFamily(user.id, event.currentTarget.checked)}
							/>
						</label>
					{/each}
				</Card>
			{/if}
			{#if features.descriptions && ai}
				<Card id="ai" title={t('admin.settings.aiDescriptionsAndQuestions')}>
					<form class="form" onsubmit={saveAI}>
						<p class="alb-meta">
							{t('admin.settings.aLocalOllamaServerReceives')}
						</p>
						<Input label={t('admin.settings.ollamaAddress')} bind:value={ai.address} />
						<Input label={t('admin.settings.modelForPictures')} bind:value={ai.visionModel} />
						<Input label={t('admin.settings.modelForQuestions')} bind:value={ai.textModel} />
						<Kv
							label={t('admin.settings.state')}
							value={!ai.address
								? t('admin.settings.notSet')
								: !ai.reachable
									? t('admin.settings.ollamaIsNotAnswering')
									: ai.modelsReady
										? t('admin.settings.running')
										: t('admin.settings.theModelsAreDownloading')}
						/>
						<Kv label={t('admin.settings.described')} value="{ai.described} / {ai.total}" />
						<Button type="submit" variant="gold" small>{t('common.save')}</Button>
					</form>
				</Card>
			{/if}
			{#if features.webhooks}
				<Card id="webhooks" title="Webhooks">
					<p class="alb-meta">
						{t('admin.settings.tellsOtherProgramsWhatHappened')}
					</p>
					{#if hookSecret}
						<Alert kind="ok"
							>{t('admin.settings.theSigningSecretShownOnly')}
							<code data-testid="hook-secret">{hookSecret}</code></Alert
						>
					{/if}
					<ul class="set-list">
						{#each webhooks as hook (hook.id)}
							<li data-hook={hook.url}>
								<span class="set-list-t">
									<b class="mono">{hook.url}</b>
									<small>
										{hook.events.join(', ')}
										{#if hook.lastStatus}· {hook.lastStatus}{/if}
									</small>
									{#if hook.lastError}
										<button
											type="button"
											class="set-clamp"
											title={hook.lastError}
											onclick={(event) => event.currentTarget.classList.toggle('open')}
											>{hook.lastError}</button
										>
									{/if}
								</span>
								<Button small onclick={() => hookAction(() => api.testWebhook(hook.id))}
									>{t('admin.settings.test')}</Button
								>
								<Button small onclick={() => hookAction(() => api.deleteWebhook(hook.id))}
									>{t('common.remove')}</Button
								>
							</li>
						{/each}
					</ul>
					<form class="form" onsubmit={addHook}>
						<Input label={t('admin.settings.webhookAddress')} bind:value={hookUrl} />
						<fieldset class="set-row set-field">
							<legend>{t('admin.settings.events')}</legend>
							<div class="set-checks">
								{#each ['asset.ready', 'person.created', 'backup.finished'] as const as name (name)}
									<label class="set-check"
										><input type="checkbox" bind:group={hookEvents} value={name} /> {name}</label
									>
								{/each}
							</div>
						</fieldset>
						<Button type="submit" variant="gold" small>{t('admin.settings.addAWebhook')}</Button>
					</form>
				</Card>
			{/if}
			<ServerSettingsCard />

			<EmailSettingsCard />

			<Card id="map" title={t('admin.settings.map')}>
				<form class="form" onsubmit={save}>
					<p class="alb-meta">
						{t('admin.settings.addressesOfAMaplibreStyle')}
					</p>
					<Input label={t('admin.settings.lightStyle')} bind:value={light} />
					<Input label={t('admin.settings.darkStyle')} bind:value={dark} />
					<Button type="submit" variant="gold" small>{t('common.save')}</Button>
				</form>
			</Card>
		</div>
	</div>
{/if}
