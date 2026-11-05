<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type ServerSettings } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let settings = $state<ServerSettings>();

	onMount(async () => {
		try {
			settings = await api.serverSettings();
		} catch {
			showToast('err', tr('Podaci se ne mogu učitati.', 'This could not be loaded.'));
		}
	});

	async function save(event: SubmitEvent) {
		event.preventDefault();
		if (!settings) return;
		try {
			settings = await api.setServerSettings(settings);
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		}
	}
</script>

<Card title={tr('Server', 'Server')}>
	{#if settings}
		<form class="form" onsubmit={save}>
			<p class="alb-meta">
				{tr(
					'Kvaliteta vrijedi za datoteke obrađene od sada. Originali se nikad ne mijenjaju.',
					'Quality applies to files processed from now on. Originals are never changed.'
				)}
			</p>
			<label>
				{tr('Dana u smeću', 'Days in the trash')}
				<input class="in" type="number" min="1" max="3650" bind:value={settings.trashDays} />
			</label>
			<label>
				{tr('Kvaliteta slika (40–100)', 'Image quality (40–100)')}
				<input class="in" type="number" min="40" max="100" bind:value={settings.imageQuality} />
			</label>
			<label>
				{tr('Veličina pregleda u pikselima', 'Preview size in pixels')}
				<input class="in" type="number" min="720" max="4096" bind:value={settings.previewSize} />
			</label>
			<label>
				{tr('Kvaliteta videa (18–40, manje je bolje)', 'Video quality (18–40, lower is better)')}
				<input class="in" type="number" min="18" max="40" bind:value={settings.videoQuality} />
			</label>
			<label>
				{tr('Najveća visina videa', 'Largest video height')}
				<select class="in" bind:value={settings.videoMaxHeight}>
					<option value={720}>720p</option>
					<option value={1080}>1080p</option>
					<option value={1440}>1440p</option>
					<option value={2160}>2160p</option>
				</select>
			</label>
			<label>
				{tr('Poruka na stranici za prijavu', 'Message on the sign-in page')}
				<textarea class="in" rows="2" maxlength="1000" bind:value={settings.loginMessage}
				></textarea>
			</label>
			<label>
				<input type="checkbox" bind:checked={settings.passwordLogin} />
				{tr('Dopusti prijavu lozinkom', 'Allow signing in with a password')}
			</label>
			<p class="alb-meta">
				{tr(
					'Ako se zaključate: docker compose exec server /mediarr security reset',
					'If you lock yourself out: docker compose exec server /mediarr security reset'
				)}
			</p>
			<div><Button type="submit" variant="gold" small>{tr('Spremi', 'Save')}</Button></div>
		</form>
	{:else}
		<Skeleton height="200px" />
	{/if}
</Card>
