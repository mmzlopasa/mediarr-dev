<script lang="ts">
	import type { UserPreferences } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import { preferences, savePreferences } from '#lib/preferences.svelte.ts';

	const toggles: { key: keyof UserPreferences; hr: string; en: string }[] = [
		{ key: 'videoAutoplay', hr: 'Video se pokreće sam', en: 'Videos start by themselves' },
		{ key: 'videoLoop', hr: 'Video se ponavlja', en: 'Videos start again when they end' },
		{ key: 'videoOriginal', hr: 'Pusti originalni video', en: 'Play the original video' },
		{ key: 'photoFull', hr: 'Otvori fotku u punoj veličini', en: 'Open photos at full size' },
		{
			key: 'confirmDelete',
			hr: 'Pitaj prije brisanja iz pregleda',
			en: 'Ask before deleting from the viewer'
		}
	];
	const sections = appNav.filter((item) => item.path !== '/');

	async function change(update: Partial<UserPreferences>) {
		const now = preferences();
		if (!now) return;
		try {
			await savePreferences({ ...now, ...update });
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		}
	}

	function toggleSection(path: string, shown: boolean) {
		const hidden = preferences()?.hiddenSections ?? [];
		change({
			hiddenSections: shown ? hidden.filter((other) => other !== path) : [...hidden, path]
		});
	}
</script>

<Card id="preferences" title={tr('Postavke', 'Preferences')}>
	{#if preferences()}
		{@const now = preferences()!}
		<div class="set-group">
			<h3>{tr('Gledanje', 'Viewing')}</h3>
			{#each toggles as toggle (toggle.key)}
				<label class="set-row">
					<span>{tr(toggle.hr, toggle.en)}</span>
					<input
						type="checkbox"
						class="switch"
						checked={Boolean(now[toggle.key])}
						onchange={(event) => change({ [toggle.key]: event.currentTarget.checked })}
					/>
				</label>
			{/each}
		</div>
		<div class="set-group">
			<h3>{tr('Uspomene, osobe i albumi', 'Memories, people and albums')}</h3>
			<label class="set-row">
				<span>{tr('Sekundi po slici u uspomenama', 'Seconds for each picture in memories')}</span>
				<input
					class="in num"
					type="number"
					min="1"
					max="60"
					value={now.memorySeconds}
					onchange={(event) => change({ memorySeconds: Number(event.currentTarget.value) })}
				/>
			</label>
			<label class="set-row">
				<span
					>{tr(
						'Najmanje fotki da se osoba prikaže',
						'Fewest photos for a person to be listed'
					)}</span
				>
				<input
					class="in num"
					type="number"
					min="1"
					max="100"
					value={now.minFaces}
					onchange={(event) => change({ minFaces: Number(event.currentTarget.value) })}
				/>
			</label>
			<label class="set-row">
				<span>{tr('Poredak u novom albumu', 'Order in a new album')}</span>
				<select
					class="in"
					value={now.albumOrder}
					onchange={(event) =>
						change({ albumOrder: event.currentTarget.value as UserPreferences['albumOrder'] })}
				>
					<option value="newest">{tr('Najnovije prvo', 'Newest first')}</option>
					<option value="oldest">{tr('Najstarije prvo', 'Oldest first')}</option>
				</select>
			</label>
		</div>
		<div class="set-group">
			<h3>{tr('Prikaži u izborniku', 'Show in the menu')}</h3>
			<div class="set-tiles">
				{#each sections as section (section.path)}
					<label class="set-tile">
						<span>{tr(section.hr, section.en)}</span>
						<input
							type="checkbox"
							class="switch"
							checked={!now.hiddenSections.includes(section.path)}
							onchange={(event) => toggleSection(section.path, event.currentTarget.checked)}
						/>
					</label>
				{/each}
			</div>
		</div>
	{:else}
		<Skeleton height="120px" />
	{/if}
</Card>
