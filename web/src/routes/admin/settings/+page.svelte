<script lang="ts">
	import { onMount } from 'svelte';
	import {
		api,
		type AnalysisProgress,
		type ExternalLibrary,
		type OIDCSettings,
		type User,
		type ImportCreate,
		type ImportEntry,
		type BackupRun,
		type BackupSettings,
		type Features,
		type Webhook
	} from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

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
				secret: oidcSecret || undefined
			});
			oidcSecret = '';
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	let imports = $state<ImportEntry[]>([]);
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
			showToast('ok', tr('Uvoz je pokrenut.', 'The import has started.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	const FEATURE_LABELS: Record<string, { hr: string; en: string }> = {
		backup: { hr: 'Zakazani backup', en: 'Scheduled backup' },
		filters: { hr: 'Filteri u editoru', en: 'Filters in the editor' },
		documents: { hr: 'Album Dokumenti', en: 'Documents album' },
		family: { hr: 'Obiteljska biblioteka', en: 'Family library' },
		webhooks: { hr: 'Webhooks', en: 'Webhooks' },
		kiosk: { hr: 'Kiosk za TV i tablet', en: 'Kiosk for TV and tablet' },
		descriptions: { hr: 'AI opisi i chat-pretraga', en: 'AI descriptions and chat search' }
	};
	let features = $state<Features>({});
	let backup = $state<BackupSettings>();
	let backupRuns = $state<BackupRun[]>([]);
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
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
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
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	async function runBackup(kind: BackupRun['kind']) {
		try {
			await api.startBackupRun(kind);
			await loadBackup();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
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
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	async function hookAction(action: () => Promise<void>) {
		try {
			await action();
			await loadHooks();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function externalAction(action: () => Promise<unknown>) {
		try {
			await action();
			external = await api.externalLibrary();
			showToast('ok', tr('Pregled je pokrenut.', 'The scan has started.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		try {
			const style = await api.setMapStyle({ light, dark });
			light = style.light;
			dark = style.dark;
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}
</script>

<svelte:head><title>{tr('Postavke', 'Settings')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr('Postavke', 'Settings')}</h1></div></div>

{#if failed}
	<Alert kind="err">{tr('Postavke se nisu učitale.', 'The settings could not be loaded.')}</Alert>
{:else if !loaded}
	<Skeleton height="200px" />
{:else}
	<Card title={tr('Pametna pretraga i lica', 'Smart search and faces')}>
		{#if analysis?.enabled}
			<Kv label={tr('Obrađeno', 'Analysed')} value="{analysis.analyzed} / {analysis.total}" />
			<Bar
				pct={analysis.total ? Math.round((analysis.analyzed / analysis.total) * 100) : 0}
				label={tr('Obrada slika', 'Picture analysis')}
			/>
		{:else}
			<p class="alb-meta">
				{tr(
					'Nije uključeno. U .env postavite COMPOSE_PROFILES=ml i ML_URL=http://ml:8000.',
					'Not turned on. In .env, set COMPOSE_PROFILES=ml and ML_URL=http://ml:8000.'
				)}
			</p>
		{/if}
	</Card>
	<Card title={tr('Vanjska biblioteka', 'External library')}>
		{#if !external?.available}
			<p class="alb-meta">
				{tr(
					'Nije uključeno. U .env postavite EXTERNAL_LIBRARY_PATH na mapu s fotkama. Mediarr je samo čita.',
					'Not turned on. In .env, set EXTERNAL_LIBRARY_PATH to a folder of photos. Mediarr only reads it.'
				)}
			</p>
		{:else}
			<p class="alb-meta">
				{tr(
					'Mediarr ovu mapu samo čita. Promjene vidi odmah na lokalnom disku, a na mrežnom shareu (SMB) tek pri pregledu svakih 6 sati ili kad ga pokrenete ručno.',
					'Mediarr only reads this folder. It sees changes at once on a local disk, but on a network share (SMB) only at the scan every 6 hours, or when you start one.'
				)}
			</p>
			<label class="form">
				<span>{tr('Čije su ovo fotke', 'Whose photos these are')}</span>
				<select bind:value={owner} disabled={(external?.assets ?? 0) > 0}>
					<option value="" disabled>{tr('Odaberite korisnika', 'Choose a user')}</option>
					{#each users as user (user.id)}
						<option value={user.id}>{user.name} ({user.email})</option>
					{/each}
				</select>
			</label>
			{#if external.ownerId}
				<Kv label={tr('Fotke i videi', 'Photos and videos')} value={String(external.assets)} />
				<Kv label={tr('Nedostupno', 'Unavailable')} value={String(external.missing)} />
				<Kv
					label={tr('Stanje', 'State')}
					value={external.scanning
						? tr('Pregled u tijeku', 'Scanning')
						: external.scanFinishedAt
							? tr('Pregledano ', 'Scanned ') + new Date(external.scanFinishedAt).toLocaleString()
							: tr('Još nije pregledano', 'Not scanned yet')}
				/>
				{#if external.scanError}<Alert kind="err">{external.scanError}</Alert>{/if}
			{/if}
			{#if !external.ownerId}
				<Button
					variant="gold"
					small
					disabled={!owner}
					onclick={() => externalAction(() => api.setExternalOwner(owner))}
					>{tr('Spremi i pregledaj', 'Save and scan')}</Button
				>
			{:else}
				<Button small onclick={() => externalAction(api.scanExternal)}
					>{tr('Pregledaj sada', 'Scan now')}</Button
				>
			{/if}
		{/if}
	</Card>
	{#if oidc}
		<Card title={tr('Jedinstvena prijava (OIDC)', 'Single sign-on (OIDC)')}>
			<form class="form" onsubmit={saveOIDC}>
				<p class="alb-meta">
					{tr(
						'Po želji. Prazan izdavatelj je isključuje, a lozinka uvijek ostaje dostupna. Adresa povratka kod pružatelja:',
						'Optional. An empty issuer turns it off, and passwords always keep working. The redirect address at the provider:'
					)}
					<code>{location.origin}/api/auth/oidc/callback</code>
				</p>
				<Input label={tr('Izdavatelj', 'Issuer')} bind:value={oidc.issuer} />
				<Input label="Client ID" bind:value={oidc.clientId} />
				<Input
					label={oidc.hasSecret
						? tr(
								'Client secret (spremljen, upišite za promjenu)',
								'Client secret (saved, type to change)'
							)
						: 'Client secret'}
					bind:value={oidcSecret}
				/>
				<Input label={tr('Natpis na gumbu', 'Button label')} bind:value={oidc.label} />
				<label>
					<input type="checkbox" bind:checked={oidc.autoCreate} />
					{tr(
						'Stvori račun onome tko ga još nema (običan korisnik)',
						'Create an account for someone who has none (a plain user)'
					)}
				</label>
				<Button type="submit" variant="gold" small>{tr('Spremi', 'Save')}</Button>
			</form>
		</Card>
	{/if}
	<Card title={tr('Uvoz', 'Import')}>
		<form class="form" onsubmit={startImport}>
			<p class="alb-meta">
				{tr(
					'Datoteka koja već postoji ne uvozi se ponovno, pa se uvoz smije ponoviti. Ništa se ne mijenja na izvoru.',
					'A file that is already here is not brought in again, so an import can be repeated. Nothing changes at the source.'
				)}
			</p>
			<label class="form">
				<span>{tr('Odakle', 'From')}</span>
				<select bind:value={importSource} data-testid="import-source">
					<option value="immich">Immich</option>
					<option value="takeout">Google Takeout</option>
					<option value="icloud">iCloud</option>
				</select>
			</label>
			<label class="form">
				<span>{tr('U čiju biblioteku', 'Into whose library')}</span>
				<select bind:value={importOwner} required data-testid="import-owner">
					<option value="" disabled>{tr('Odaberite korisnika', 'Choose a user')}</option>
					{#each users as user (user.id)}
						<option value={user.id}>{user.name} ({user.email})</option>
					{/each}
				</select>
			</label>
			{#if importSource === 'immich'}
				<Input label={tr('Adresa Immicha', 'Immich address')} bind:value={importAddress} />
				<Input label={tr('Immich API ključ', 'Immich API key')} bind:value={importKey} />
				<p class="alb-meta">
					{tr(
						'Ključ se briše kad uvoz završi. Lica se prepoznaju iznova ako je uključena analiza slika, a imena se preuzimaju.',
						'The key is erased when the import ends. Faces are recognised again if picture analysis is on, and their names are kept.'
					)}
				</p>
			{:else}
				<Input
					label={tr('Mapa unutar vanjske biblioteke', 'Folder inside the external library')}
					bind:value={importFolder}
				/>
				<p class="alb-meta">
					{tr(
						'Raspakirajte izvoz u mapu iz EXTERNAL_LIBRARY_PATH. Datoteke se kopiraju, a izvoz ostaje netaknut.',
						'Unpack the export into the folder of EXTERNAL_LIBRARY_PATH. The files are copied, and the export stays untouched.'
					)}
				</p>
			{/if}
			<Button type="submit" variant="gold" small>{tr('Pokreni uvoz', 'Start the import')}</Button>
		</form>
		{#each imports as entry (entry.id)}
			<div class="alb-list" data-import={entry.source}>
				<b>{entry.source} → {entry.userEmail}</b>
				<span class="alb-meta">
					{entry.status} · {tr('dodano', 'added')}
					{entry.added} · {tr('preskočeno', 'skipped')}
					{entry.skipped} · {tr('neuspjelo', 'failed')}
					{entry.failed}
					{#if entry.lastError}· {entry.lastError}{/if}
				</span>
				{#if entry.status === 'running'}
					<Button
						small
						onclick={async () => {
							await api.cancelImport(entry.id);
							await loadImports();
						}}>{tr('Zaustavi', 'Stop')}</Button
					>
				{/if}
			</div>
		{/each}
	</Card>
	<Card title={tr('Dodaci', 'Additions')}>
		<p class="alb-meta">
			{tr(
				'Svaki je isključen dok ga ne uključite, i tada ne mijenja ništa.',
				'Each is off until you turn it on, and changes nothing until then.'
			)}
		</p>
		{#each Object.keys(FEATURE_LABELS) as name (name)}
			<label class="alb-list">
				<input
					type="checkbox"
					data-feature={name}
					checked={features[name] ?? false}
					onchange={(event) => toggleFeature(name, event.currentTarget.checked)}
				/>
				{tr(FEATURE_LABELS[name].hr, FEATURE_LABELS[name].en)}
			</label>
		{/each}
	</Card>
	{#if backup}
		<Card title="Backup">
			<form class="form" onsubmit={saveBackup}>
				<p class="alb-meta">
					{tr(
						`Originali i baza, šifrirano. Odredište je mapa unutar ${backup.localFolder}, ili s3: ili b2: adresa. Sličice se ne spremaju jer se mogu ponovno napraviti.`,
						`Originals and the database, encrypted. The destination is a folder inside ${backup.localFolder}, or an s3: or b2: address. Previews are left out, as they can be made again.`
					)}
				</p>
				<Alert kind="warn"
					>{tr(
						'Zapišite lozinku negdje izvan ovog servera. Bez nje se backup nikako ne može vratiti.',
						'Write the password down somewhere other than this server. Without it, a backup can never be brought back.'
					)}</Alert
				>
				<Input label={tr('Odredište', 'Destination')} bind:value={backup.repository} />
				<Input
					label={backup.hasPassword
						? tr('Lozinka (spremljena, upišite za promjenu)', 'Password (saved, type to change)')
						: tr('Lozinka backupa', 'Backup password')}
					bind:value={backupPassword}
				/>
				<Input
					label={backup.hasS3Key
						? tr('Pristupni ključ (spremljen)', 'Access key (saved)')
						: tr('Pristupni ključ (S3, B2)', 'Access key (S3, B2)')}
					bind:value={backupKey}
				/>
				<Input
					label={tr('Tajni ključ (S3, B2)', 'Secret key (S3, B2)')}
					bind:value={backupSecret}
				/>
				<Input label={tr('Sat u danu (0-23)', 'Hour of the day (0-23)')} bind:value={backupHour} />
				<Button data-testid="backup-save" type="submit" variant="gold" small
					>{tr('Spremi', 'Save')}</Button
				>
			</form>
			<div class="dup-actions">
				<Button small onclick={() => runBackup('backup')}>{tr('Backup sada', 'Back up now')}</Button
				>
				<Button small onclick={() => runBackup('restore_test')}
					>{tr('Testiraj vraćanje', 'Test bringing it back')}</Button
				>
			</div>
			{#each backupRuns as run (run.id)}
				<div class="alb-list" data-backup-run={run.kind}>
					<b>{run.kind === 'backup' ? 'Backup' : tr('Test vraćanja', 'Restore test')}</b>
					<span class="alb-meta">
						{run.status} · {new Date(run.startedAt).toLocaleString()} · {tr('datoteka', 'files')}
						{run.files}
						{#if run.message}· {run.message}{/if}
					</span>
				</div>
			{/each}
		</Card>
	{/if}
	{#if features.webhooks}
		<Card title="Webhooks">
			<p class="alb-meta">
				{tr(
					'Javlja drugim programima što se dogodilo, samo po ID-u, potpisano zaglavljem X-Mediarr-Signature. Adrese na lokalnoj mreži su dopuštene, a sam ovaj server i metadata servisi nisu.',
					'Tells other programs what happened, by id only, signed in the X-Mediarr-Signature header. Addresses on the local network are allowed, but not this server itself or metadata services.'
				)}
			</p>
			{#if hookSecret}
				<Alert kind="ok"
					>{tr('Tajna za potpis, prikazuje se samo sada:', 'The signing secret, shown only now:')}
					<code data-testid="hook-secret">{hookSecret}</code></Alert
				>
			{/if}
			{#each webhooks as hook (hook.id)}
				<div class="alb-list" data-hook={hook.url}>
					<b>{hook.url}</b>
					<span class="alb-meta">
						{hook.events.join(', ')}
						{#if hook.lastStatus}· {hook.lastStatus}{/if}
						{#if hook.lastError}· {hook.lastError}{/if}
					</span>
					<Button small onclick={() => hookAction(() => api.testWebhook(hook.id))}
						>{tr('Testiraj', 'Test')}</Button
					>
					<Button small onclick={() => hookAction(() => api.deleteWebhook(hook.id))}
						>{tr('Ukloni', 'Remove')}</Button
					>
				</div>
			{/each}
			<form class="form" onsubmit={addHook}>
				<Input label={tr('Adresa webhooka', 'Webhook address')} bind:value={hookUrl} />
				{#each ['asset.ready', 'person.created', 'backup.finished'] as const as name (name)}
					<label><input type="checkbox" bind:group={hookEvents} value={name} /> {name}</label>
				{/each}
				<Button type="submit" variant="gold" small>{tr('Dodaj webhook', 'Add a webhook')}</Button>
			</form>
		</Card>
	{/if}
	<Card title={tr('Karta', 'Map')}>
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{tr(
					'Adrese MapLibre stila za podlogu karte. Prazno vraća zadanu podlogu.',
					'Addresses of a MapLibre style for the map background. Empty goes back to the default.'
				)}
			</p>
			<Input label={tr('Svijetli stil', 'Light style')} bind:value={light} />
			<Input label={tr('Tamni stil', 'Dark style')} bind:value={dark} />
			<Button type="submit" variant="gold" small>{tr('Spremi', 'Save')}</Button>
		</form>
	</Card>
{/if}
