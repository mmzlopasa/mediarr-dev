<script lang="ts">
	import { untrack } from 'svelte';
	import { api, type FixResult, type Place } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t, k, type Key } from '#lib/i18n.svelte.ts';

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
			showToast('ok', t('fixDialog.changedChanged', { changed: done.changed }));
			open = false;
			onDone();
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		} finally {
			busy = false;
		}
	}

	const dateChoices: [DateAction, Key][] = [
		['shift', k('fixDialog.date.shift')],
		['anchor', k('fixDialog.date.anchor')],
		['set', k('fixDialog.date.set')],
		['zoneFromPlace', k('fixDialog.date.zoneFromPlace')],
		['travel', k('fixDialog.date.travel')],
		['useFile', k('fixDialog.date.useFile')]
	];
	const placeChoices: [PlaceAction, Key][] = [
		['fromNeighbours', k('fixDialog.place.fromNeighbours')],
		['fromTrack', k('fixDialog.place.fromTrack')],
		['set', k('fixDialog.place.set')],
		['clear', k('fixDialog.place.clear')],
		['useFile', k('fixDialog.place.useFile')]
	];
</script>

<Dialog
	title={kind === 'dates'
		? t('fixDialog.dateAndTimeIdscount', { idsCount: ids.length })
		: t('fixDialog.locationIdscount', { idsCount: ids.length })}
	bind:open
>
	<form
		class="form fix"
		onsubmit={(event) => event.preventDefault()}
		aria-label={kind === 'dates' ? t('common.dateAndTime') : t('common.location')}
	>
		<div class="fix-choices" role="radiogroup">
			{#if kind === 'dates'}
				{#each dateChoices as [value, label] (value)}
					<label class="sf-chip" class:on={dateAction === value}
						><input type="radio" bind:group={dateAction} {value} />{t(label)}</label
					>
				{/each}
			{:else}
				{#each placeChoices as [value, label] (value)}
					<label class="sf-chip" class:on={placeAction === value}
						><input type="radio" bind:group={placeAction} {value} />{t(label)}</label
					>
				{/each}
			{/if}
		</div>

		{#if kind === 'dates' && dateAction === 'shift'}
			<p class="alb-meta">
				{t('fixDialog.whenTheCameraSClock')}
			</p>
			<div class="fix-row">
				<select class="in" bind:value={later} aria-label={t('fixDialog.direction')}>
					<option value={false}>{t('fixDialog.earlier')}</option>
					<option value={true}>{t('fixDialog.later')}</option>
				</select>
				<label
					><input class="in" type="number" min="0" bind:value={days} />{t('fixDialog.days')}</label
				>
				<label
					><input class="in" type="number" min="0" bind:value={hours} />{t(
						'fixDialog.hours'
					)}</label
				>
				<label
					><input class="in" type="number" min="0" bind:value={minutes} />{t(
						'fixDialog.minutes'
					)}</label
				>
			</div>
		{:else if kind === 'dates' && dateAction === 'anchor'}
			<p class="alb-meta">
				{t('fixDialog.typeWhenTheFirstSelected')}
			</p>
			<label class="fix-field"
				><span>{t('fixDialog.itSaysNow')}</span><input
					class="in"
					type="datetime-local"
					value={anchorBefore}
					disabled
				/></label
			>
			<label class="fix-field"
				><span>{t('fixDialog.really')}</span><input
					class="in"
					type="datetime-local"
					bind:value={anchorAfter}
				/></label
			>
		{:else if kind === 'dates' && dateAction === 'set'}
			<p class="alb-meta">
				{t('fixDialog.oneDateForAllA')}
			</p>
			<label class="fix-field"
				><span>{t('common.dateAndTime')}</span><input
					class="in"
					type="datetime-local"
					bind:value={setAt}
				/></label
			>
		{:else if kind === 'dates' && dateAction === 'zoneFromPlace'}
			<p class="alb-meta">
				{t('fixDialog.photosWithALocationGet')}
			</p>
		{:else if kind === 'dates' && dateAction === 'travel'}
			<p class="alb-meta">
				{t('fixDialog.whenTheCameraKeptHome')}
			</p>
			<datalist id="fix-zones"
				>{#each zones as zone (zone)}<option value={zone}></option>{/each}</datalist
			>
			<label class="fix-field"
				><span>{t('fixDialog.theCameraSClockWas')}</span><input
					class="in"
					list="fix-zones"
					bind:value={cameraZone}
				/></label
			>
			<label class="fix-field"
				><span>{t('fixDialog.theyWereTakenIn')}</span><input
					class="in"
					list="fix-zones"
					bind:value={placeZone}
					placeholder="Asia/Tokyo"
				/></label
			>
		{:else if kind === 'dates'}
			<p class="alb-meta">
				{t('fixDialog.datesSetByHandAre')}
			</p>
		{:else if placeAction === 'fromNeighbours'}
			<p class="alb-meta">
				{t('fixDialog.photosWithoutALocationGet')}
			</p>
			<label class="fix-field"
				><span>{t('fixDialog.atMostMinutesApart')}</span><input
					class="in"
					type="number"
					min="1"
					max="1440"
					bind:value={nearMinutes}
				/></label
			>
		{:else if placeAction === 'fromTrack'}
			<p class="alb-meta">
				{t('fixDialog.photosWithoutALocationGet2')}
			</p>
			<label class="fix-field"
				><span>{trackName || t('fixDialog.gpxFile')}</span><input
					type="file"
					accept=".gpx,application/gpx+xml"
					onchange={readTrack}
				/></label
			>
		{:else if placeAction === 'set'}
			<label class="fix-field"
				><span>{t('fixDialog.findAPlace')}</span><input
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
					><span>{t('fixDialog.latitude')}</span><input
						class="in"
						type="number"
						step="any"
						bind:value={latitude}
					/></label
				>
				<label
					><span>{t('fixDialog.longitude')}</span><input
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
					? t('fixDialog.theLocationGoesAndStays')
					: t('fixDialog.locationsSetByHandAre')}
			</p>
		{/if}

		<section class="fix-preview" aria-label={t('fixDialog.preview')} aria-live="polite">
			{#if problem}
				<p class="st-error" role="alert">{problem}</p>
			{:else if preview}
				<p>
					<b>{t('fixDialog.willChangeChanged', { changed: preview.changed })}</b>
					{#if preview.skipped}
						· {t('fixDialog.nothingToGoBySkipped', { skipped: preview.skipped })}{/if}
				</p>
				<ul class="st-previews">
					{#each preview.changes as change (change.id)}
						<li>
							<span>{change.name}</span><b class="mono"
								>{change.before || '—'} → {change.after || t('fixDialog.noLocation')}</b
							>
						</li>
					{/each}
				</ul>
			{/if}
		</section>
	</form>
	{#snippet footer()}
		<Button onclick={() => (open = false)}>{t('common.cancel')}</Button>
		<Button variant="gold" disabled={busy || !preview?.changed} onclick={apply}
			>{t('common.save')}</Button
		>
	{/snippet}
</Dialog>
