<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AnalysisProgress, type ExternalLibrary, type User } from '#lib/api.ts';
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
