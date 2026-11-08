<script lang="ts">
	import { untrack } from 'svelte';
	import { api, type FixResult, type Place } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	type DateAction = 'shift' | 'anchor' | 'set' | 'zoneFromPlace' | 'travel' | 'useFile';
	type PlaceAction = 'set' | 'clear' | 'fromNeighbours' | 'fromTrack' | 'useFile';

	/** Fixes the dates or the places of many photos, showing what changes before it does. */
	let {
		ids,
		kind,
		open = $bindable(false),
		onDone
	}: {
		ids: string[];
		kind: 'dates' | 'locations';
		open?: boolean;
		onDone: () => void;
	} = $props();

	let dateAction = $state<DateAction>('shift');
	let placeAction = $state<PlaceAction>('fromNeighbours');
	let later = $state(false);
	let days = $state(0);
	let hours = $state(0);
	let minutes = $state(0);
	let anchorBefore = $state('');
	let anchorAfter = $state('');
	let setAt = $state('');
	const zones =
		typeof Intl.supportedValuesOf === 'function' ? Intl.supportedValuesOf('timeZone') : [];
	let cameraZone = $state(Intl.DateTimeFormat().resolvedOptions().timeZone);
	let placeZone = $state('');
	let search = $state('');
	let places = $state<Place[]>([]);
	let latitude = $state('');
	let longitude = $state('');
	let nearMinutes = $state(30);
	let track = $state('');
	let trackName = $state('');
	let preview = $state<FixResult>();
	let problem = $state('');
	let busy = $state(false);

	const pad = (value: number) => String(value).padStart(2, '0');

	/** A typed local time with the offset this computer has on that day. */
	function withOffset(local: string) {
		const offset = -new Date(local).getTimezoneOffset();
		const sign = offset < 0 ? '-' : '+';
		const size = Math.abs(offset);
		return `${local}:00${sign}${pad(Math.floor(size / 60))}:${pad(size % 60)}`;
	}

	// "This one was really taken at…": its time now, to shift all by the same.
	$effect(() => {
		if (!open || kind !== 'dates' || dateAction !== 'anchor' || anchorBefore || !ids[0]) return;
		api
			.asset(ids[0])
			.then((detail) => {
				anchorBefore = detail.localAt.slice(0, 16);
				anchorAfter ||= anchorBefore;
			})
			.catch(() => undefined);
	});

	function shiftMinutes(): number | undefined {
		if (dateAction === 'anchor') {
			if (!anchorBefore || !anchorAfter) return undefined;
			// Both are clock times as typed, so their difference is the shift.
			return Math.round((Date.parse(`${anchorAfter}Z`) - Date.parse(`${anchorBefore}Z`)) / 60000);
		}
		const total = (days * 24 + hours) * 60 + minutes;
		return later ? total : -total;
	}

	function body(dryRun: boolean): Record<string, unknown> | undefined {
		if (kind === 'dates') {
			switch (dateAction) {
				case 'shift':
				case 'anchor': {
					const shift = shiftMinutes();
					return shift ? { ids, action: 'shift', minutes: shift, dryRun } : undefined;
				}
				case 'set':
					return setAt ? { ids, action: 'set', takenAt: withOffset(setAt), dryRun } : undefined;
				case 'travel':
					return cameraZone && placeZone
						? { ids, action: 'travel', cameraZone, placeZone, dryRun }
						: undefined;
				default:
					return { ids, action: dateAction, dryRun };
			}
		}
		switch (placeAction) {
			case 'set':
				return latitude && longitude
					? { ids, action: 'set', latitude: Number(latitude), longitude: Number(longitude), dryRun }
					: undefined;
			case 'fromNeighbours':
				return { ids, action: 'fromNeighbours', minutes: nearMinutes, dryRun };
			case 'fromTrack':
				return track ? { ids, action: 'fromTrack', track, dryRun } : undefined;
			default:
				return { ids, action: placeAction, dryRun };
		}
	}

	async function send(payload: Record<string, unknown>) {
		const response = await fetch(kind === 'dates' ? '/api/assets/dates' : '/api/assets/locations', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});
		const answer = await response.json().catch(() => ({}));
		if (!response.ok) throw new Error(answer.message ?? `${response.status}`);
		return answer as FixResult;
	}

	// The preview follows each change, a moment after typing stops.
	let timer: ReturnType<typeof setTimeout> | undefined;
	$effect(() => {
		const payload = body(true);
		clearTimeout(timer);
		if (!open) return;
		untrack(() => {
			preview = undefined;
			problem = '';
		});
		if (!payload) return;
		timer = setTimeout(async () => {
			try {
				preview = await send(payload);
			} catch (cause) {
				problem = cause instanceof Error ? cause.message : '';
			}
		}, 350);
		return () => clearTimeout(timer);
	});

	async function findPlaces() {
		try {
			places = search.trim().length < 2 ? [] : (await api.searchPlaces(search.trim())).places;
		} catch {
			places = [];
		}
	}

	async function readTrack(event: Event) {
		const file = (event.currentTarget as HTMLInputElement).files?.[0];
		if (!file) return;
		trackName = file.name;
		track = await file.text();
	}

	async function apply() {
		const payload = body(false);
		if (!payload) return;
		busy = true;
		try {
			const done = await send(payload);
			showToast('ok', tr(`Promijenjeno: ${done.changed}`, `Changed: ${done.changed}`));
			open = false;
			onDone();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		} finally {
			busy = false;
		}
	}

	const dateChoices: [DateAction, string, string][] = [
		['shift', 'Pomakni', 'Shift'],
		['anchor', 'Ova je snimljena u…', 'This one was taken at…'],
		['set', 'Postavi datum', 'Set a date'],
		['zoneFromPlace', 'Zona s lokacije', 'Zone from the place'],
		['travel', 'Putovanje', 'A trip'],
		['useFile', 'Iz datoteke', 'From the file']
	];
	const placeChoices: [PlaceAction, string, string][] = [
		['fromNeighbours', 'Od susjednih fotki', 'From nearby photos'],
		['fromTrack', 'Iz GPX traga', 'From a GPX track'],
		['set', 'Postavi mjesto', 'Set a place'],
		['clear', 'Makni lokaciju', 'Take the location away'],
		['useFile', 'Iz datoteke', 'From the file']
	];
</script>

<Dialog
	title={kind === 'dates'
		? tr(`Datum i vrijeme · ${ids.length}`, `Date and time · ${ids.length}`)
		: tr(`Lokacija · ${ids.length}`, `Location · ${ids.length}`)}
	bind:open
>
	<form
		class="form fix"
		onsubmit={(event) => event.preventDefault()}
		aria-label={kind === 'dates'
			? tr('Datum i vrijeme', 'Date and time')
			: tr('Lokacija', 'Location')}
	>
		<div class="fix-choices" role="radiogroup">
			{#if kind === 'dates'}
				{#each dateChoices as [value, hr, en] (value)}
					<label class="sf-chip" class:on={dateAction === value}
						><input type="radio" bind:group={dateAction} {value} />{tr(hr, en)}</label
					>
				{/each}
			{:else}
				{#each placeChoices as [value, hr, en] (value)}
					<label class="sf-chip" class:on={placeAction === value}
						><input type="radio" bind:group={placeAction} {value} />{tr(hr, en)}</label
					>
				{/each}
			{/if}
		</div>

		{#if kind === 'dates' && dateAction === 'shift'}
			<p class="alb-meta">
				{tr('Kad je sat fotoaparata bio kriv.', "When the camera's clock was wrong.")}
			</p>
			<div class="fix-row">
				<select class="in" bind:value={later} aria-label={tr('Smjer', 'Direction')}>
					<option value={false}>{tr('Ranije', 'Earlier')}</option>
					<option value={true}>{tr('Kasnije', 'Later')}</option>
				</select>
				<label
					><input class="in" type="number" min="0" bind:value={days} />{tr('dana', 'days')}</label
				>
				<label
					><input class="in" type="number" min="0" bind:value={hours} />{tr('sati', 'hours')}</label
				>
				<label
					><input class="in" type="number" min="0" bind:value={minutes} />{tr(
						'minuta',
						'minutes'
					)}</label
				>
			</div>
		{:else if kind === 'dates' && dateAction === 'anchor'}
			<p class="alb-meta">
				{tr(
					'Upišite kad je prva odabrana fotka stvarno snimljena; sve se pomaknu za istu razliku.',
					'Type when the first selected photo was really taken; all move by the same.'
				)}
			</p>
			<label class="fix-field"
				><span>{tr('Sad piše', 'It says now')}</span><input
					class="in"
					type="datetime-local"
					value={anchorBefore}
					disabled
				/></label
			>
			<label class="fix-field"
				><span>{tr('Stvarno', 'Really')}</span><input
					class="in"
					type="datetime-local"
					bind:value={anchorAfter}
				/></label
			>
		{:else if kind === 'dates' && dateAction === 'set'}
			<p class="alb-meta">
				{tr(
					'Isti datum svima, minutu razmaka, da ostanu u svom redu. Za skenirane fotke.',
					'One date for all, a minute apart so they keep their order. For scanned photos.'
				)}
			</p>
			<label class="fix-field"
				><span>{tr('Datum i vrijeme', 'Date and time')}</span><input
					class="in"
					type="datetime-local"
					bind:value={setAt}
				/></label
			>
		{:else if kind === 'dates' && dateAction === 'zoneFromPlace'}
			<p class="alb-meta">
				{tr(
					'Fotke s lokacijom dobiju vremensku zonu mjesta (s ljetnim vremenom); sat ostaje kakav je bio.',
					'Photos with a location get the time zone of the place, summer time included; the clock stays as it was.'
				)}
			</p>
		{:else if kind === 'dates' && dateAction === 'travel'}
			<p class="alb-meta">
				{tr(
					'Kad je fotoaparat na putu ostao na domaćem vremenu.',
					"When the camera kept home's time on a trip."
				)}
			</p>
			<datalist id="fix-zones"
				>{#each zones as zone (zone)}<option value={zone}></option>{/each}</datalist
			>
			<label class="fix-field"
				><span>{tr('Sat fotoaparata bio je na', "The camera's clock was on")}</span><input
					class="in"
					list="fix-zones"
					bind:value={cameraZone}
				/></label
			>
			<label class="fix-field"
				><span>{tr('Snimljene su u', 'They were taken in')}</span><input
					class="in"
					list="fix-zones"
					bind:value={placeZone}
					placeholder="Asia/Tokyo"
				/></label
			>
		{:else if kind === 'dates'}
			<p class="alb-meta">
				{tr('Ručno postavljeni datumi se brišu.', 'Dates set by hand are taken away.')}
			</p>
		{:else if placeAction === 'fromNeighbours'}
			<p class="alb-meta">
				{tr(
					'Fotke bez lokacije dobiju mjesto fotke s lokacijom snimljene najbliže njima, npr. fotoaparat uz mobitel.',
					'Photos without a location get the place of the photo with one taken closest to them, such as a camera beside a phone.'
				)}
			</p>
			<label class="fix-field"
				><span>{tr('Najviše minuta razmaka', 'At most minutes apart')}</span><input
					class="in"
					type="number"
					min="1"
					max="1440"
					bind:value={nearMinutes}
				/></label
			>
		{:else if placeAction === 'fromTrack'}
			<p class="alb-meta">
				{tr(
					'Fotke bez lokacije dobiju mjesto iz traga u trenutku snimanja. Najprije neka datum bude točan.',
					'Photos without a location get the place from the track at the moment they were taken. Get the date right first.'
				)}
			</p>
			<label class="fix-field"
				><span>{trackName || tr('GPX datoteka', 'GPX file')}</span><input
					type="file"
					accept=".gpx,application/gpx+xml"
					onchange={readTrack}
				/></label
			>
		{:else if placeAction === 'set'}
			<label class="fix-field"
				><span>{tr('Pronađi mjesto', 'Find a place')}</span><input
					class="in"
					bind:value={search}
					oninput={findPlaces}
					autocomplete="off"
				/></label
			>
			<div class="fix-choices">
				{#each places as place (`${place.name}${place.state}${place.country}${place.latitude}`)}
					<Button
						small
						onclick={() => {
							latitude = String(place.latitude);
							longitude = String(place.longitude);
							search = place.name;
							places = [];
						}}>{[place.name, place.state, place.country].filter(Boolean).join(', ')}</Button
					>
				{/each}
			</div>
			<div class="fix-row">
				<label
					><span>{tr('Širina', 'Latitude')}</span><input
						class="in"
						type="number"
						step="any"
						bind:value={latitude}
					/></label
				>
				<label
					><span>{tr('Dužina', 'Longitude')}</span><input
						class="in"
						type="number"
						step="any"
						bind:value={longitude}
					/></label
				>
			</div>
		{:else}
			<p class="alb-meta">
				{placeAction === 'clear'
					? tr('Lokacija se makne i ostaje maknuta.', 'The location goes, and stays gone.')
					: tr('Ručno postavljene lokacije se brišu.', 'Locations set by hand are taken away.')}
			</p>
		{/if}

		<section class="fix-preview" aria-label={tr('Pregled', 'Preview')} aria-live="polite">
			{#if problem}
				<p class="st-error" role="alert">{problem}</p>
			{:else if preview}
				<p>
					<b>{tr(`Promijenit će se: ${preview.changed}`, `Will change: ${preview.changed}`)}</b>
					{#if preview.skipped}
						· {tr(
							`bez podataka za to: ${preview.skipped}`,
							`nothing to go by: ${preview.skipped}`
						)}{/if}
				</p>
				<ul class="st-previews">
					{#each preview.changes as change (change.id)}
						<li>
							<span>{change.name}</span><b class="mono"
								>{change.before || '—'} → {change.after || tr('bez lokacije', 'no location')}</b
							>
						</li>
					{/each}
				</ul>
			{/if}
		</section>
	</form>
	{#snippet footer()}
		<Button onclick={() => (open = false)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="gold" disabled={busy || !preview?.changed} onclick={apply}
			>{tr('Spremi', 'Save')}</Button
		>
	{/snippet}
</Dialog>
