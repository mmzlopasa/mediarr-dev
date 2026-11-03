<script lang="ts">
	import { onMount } from 'svelte';
	import { api } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let light = $state('');
	let dark = $state('');
	let loaded = $state(false);
	let failed = $state(false);

	onMount(async () => {
		try {
			const style = await api.mapStyle();
			light = style.light;
			dark = style.dark;
			loaded = true;
		} catch {
			failed = true;
		}
	});

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
