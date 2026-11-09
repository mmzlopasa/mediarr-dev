<script lang="ts">
	import { api, type AssetDetail } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	type Place = {
		name: string;
		state: string;
		country: string;
		latitude: number;
		longitude: number;
	};

	let {
		detail,
		onClose,
		onSaved
	}: { detail: AssetDetail; onClose: () => void; onSaved: () => void | Promise<void> } = $props();

	const initial = $derived(detail);
	let open = $state(true);
	let when = $state('');
	let latitude = $state('');
	let longitude = $state('');
	let caption = $state('');
	let search = $state('');
	let places = $state<Place[]>([]);
	let filled = $state(false);

	$effect(() => {
		if (filled) return;
		filled = true;
		when = initial.localAt.slice(0, 16);
		latitude = initial.latitude === undefined ? '' : String(initial.latitude);
		longitude = initial.longitude === undefined ? '' : String(initial.longitude);
		caption = initial.caption ?? '';
	});

	$effect(() => {
		if (!open) onClose();
	});

	// The offset of where it was taken stays, so that only the time the person typed changes.
	function withOffset(local: string): string {
		const minutes = detail.offsetMinutes ?? -new Date(local).getTimezoneOffset();
		const sign = minutes < 0 ? '-' : '+';
		const size = Math.abs(minutes);
		const pad = (value: number) => String(value).padStart(2, '0');
		return `${local}:00${sign}${pad(Math.floor(size / 60))}:${pad(size % 60)}`;
	}

	async function findPlaces() {
		try {
			places = search.trim().length < 2 ? [] : (await api.searchPlaces(search.trim())).places;
		} catch {
			places = [];
		}
	}

	function choose(place: Place) {
		latitude = String(place.latitude);
		longitude = String(place.longitude);
		search = place.name;
		places = [];
	}

	async function send(body: Parameters<typeof api.setAssetFacts>[1]) {
		try {
			await api.setAssetFacts(detail.id, body);
			await onSaved();
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		const located = latitude !== '' && longitude !== '';
		await send({
			caption,
			...(when && when !== detail.localAt.slice(0, 16) ? { takenAt: withOffset(when) } : {}),
			...(located ? { latitude: Number(latitude), longitude: Number(longitude) } : {})
		});
	}
</script>

<Dialog title={t('assetFactsDialog.editDetails')} bind:open>
	<form class="form" onsubmit={save}>
		<Input label={t('common.dateAndTime')} type="datetime-local" bind:value={when} />
		<Input
			label={t('assetFactsDialog.findAPlace')}
			bind:value={search}
			oninput={findPlaces}
			autocomplete="off"
		/>
		{#each places as place (`${place.name}${place.state}${place.country}${place.latitude}`)}
			<Button small onclick={() => choose(place)}>
				{[place.name, place.state, place.country].filter(Boolean).join(', ')}
			</Button>
		{/each}
		<Input
			label={t('assetFactsDialog.latitude')}
			type="number"
			step="any"
			min="-90"
			max="90"
			bind:value={latitude}
		/>
		<Input
			label={t('assetFactsDialog.longitude')}
			type="number"
			step="any"
			min="-180"
			max="180"
			bind:value={longitude}
		/>
		<label>
			{t('common.description')}
			<textarea class="in" rows="3" maxlength="2000" bind:value={caption}></textarea>
		</label>
		<div class="integrity-run">
			<Button type="submit" variant="gold" small>{t('common.save')}</Button>
			<Button small onclick={() => send({ useFile: true })}>
				{t('assetFactsDialog.useWhatTheFileSays')}
			</Button>
		</div>
	</form>
</Dialog>
