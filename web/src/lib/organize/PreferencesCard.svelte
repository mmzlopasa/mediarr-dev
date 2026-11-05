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

<Card title={tr('Postavke', 'Preferences')}>
	{#if preferences()}
		{@const now = preferences()!}
		<div class="form">
			{#each toggles as toggle (toggle.key)}
				<label>
					<input
						type="checkbox"
						checked={Boolean(now[toggle.key])}
						onchange={(event) => change({ [toggle.key]: event.currentTarget.checked })}
					/>
					{tr(toggle.hr, toggle.en)}
				</label>
			{/each}
			<label>
				{tr('Sekundi po slici u uspomenama', 'Seconds for each picture in memories')}
				<input
					class="in"
					type="number"
					min="1"
					max="60"
					value={now.memorySeconds}
					onchange={(event) => change({ memorySeconds: Number(event.currentTarget.value) })}
				/>
			</label>
			<label>
				{tr('Najmanje fotki da se osoba prikaže', 'Fewest photos for a person to be listed')}
				<input
					class="in"
					type="number"
					min="1"
					max="100"
					value={now.minFaces}
					onchange={(event) => change({ minFaces: Number(event.currentTarget.value) })}
				/>
			</label>
			<label>
				{tr('Poredak u novom albumu', 'Order in a new album')}
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
			<b>{tr('Prikaži u izborniku', 'Show in the menu')}</b>
			{#each sections as section (section.path)}
				<label>
					<input
						type="checkbox"
						checked={!now.hiddenSections.includes(section.path)}
						onchange={(event) => toggleSection(section.path, event.currentTarget.checked)}
					/>
					{tr(section.hr, section.en)}
				</label>
			{/each}
		</div>
	{:else}
		<Skeleton height="120px" />
	{/if}
</Card>
