<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type HiddenMemories, type UserPreferences } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t, k, type Key } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import { preferences, savePreferences } from '#lib/preferences.svelte.ts';

	const toggles: { key: keyof UserPreferences; label: Key }[] = [
		{ key: 'videoAutoplay', label: k('preferencesCard.videosStartByThemselves') },
		{ key: 'videoLoop', label: k('preferencesCard.videosStartAgainWhenThey') },
		{ key: 'videoOriginal', label: k('preferencesCard.playTheOriginalVideo') },
		{ key: 'photoFull', label: k('preferencesCard.openPhotosAtFullSize') },
		{
			key: 'confirmDelete',
			label: k('preferencesCard.askBeforeDeletingFromThe')
		}
	];
	const sections = appNav.filter((item) => item.path !== '/');

	type MemoryKind = NonNullable<UserPreferences['memoryKindsOff']>[number];
	const memoryKinds: { kind: MemoryKind; label: Key }[] = [
		{ kind: 'on_this_day', label: k('preferencesCard.memoryOnThisDay') },
		{ kind: 'week', label: k('preferencesCard.memoryWeek') },
		{ kind: 'trip', label: k('preferencesCard.memoryTrip') },
		{ kind: 'person_years', label: k('preferencesCard.memoryPersonYears') },
		{ kind: 'birthday', label: k('preferencesCard.memoryBirthday') },
		{ kind: 'year_review', label: k('preferencesCard.memoryYearReview') },
		{ kind: 'month_ago', label: k('preferencesCard.memoryMonthAgo') }
	];

	let hidden = $state<HiddenMemories>();

	async function loadHidden() {
		try {
			hidden = await api.hiddenMemories();
		} catch {
			hidden = undefined;
		}
	}

	onMount(loadHidden);

	function toggleKind(kind: MemoryKind, shown: boolean) {
		const off = preferences()?.memoryKindsOff ?? [];
		change({ memoryKindsOff: shown ? off.filter((other) => other !== kind) : [...off, kind] });
	}

	async function showPersonAgain(id: string) {
		try {
			await api.setMemoryPersonHidden(id, false);
			await loadHidden();
		} catch {
			showToast('err', t('common.notSaved'));
		}
	}

	async function showAllAgain() {
		try {
			await api.restoreHiddenMemories();
			await loadHidden();
		} catch {
			showToast('err', t('common.notSaved'));
		}
	}

	async function change(update: Partial<UserPreferences>) {
		const now = preferences();
		if (!now) return;
		try {
			await savePreferences({ ...now, ...update });
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
	}

	function toggleSection(path: string, shown: boolean) {
		const hidden = preferences()?.hiddenSections ?? [];
		change({
			hiddenSections: shown ? hidden.filter((other) => other !== path) : [...hidden, path]
		});
	}
</script>

<Card id="preferences" title={t('preferencesCard.preferences')}>
	{#if preferences()}
		{@const now = preferences()!}
		<div class="set-group">
			<h3>{t('preferencesCard.viewing')}</h3>
			{#each toggles as toggle (toggle.key)}
				<label class="set-row">
					<span>{t(toggle.label)}</span>
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
			<h3>{t('preferencesCard.memoriesPeopleAndAlbums')}</h3>
			<label class="set-row">
				<span>{t('preferencesCard.secondsForEachPictureIn')}</span>
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
				<span>{t('preferencesCard.fewestPhotosForAPerson')}</span>
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
				<span>{t('preferencesCard.orderInANewAlbum')}</span>
				<select
					class="in"
					value={now.albumOrder}
					onchange={(event) =>
						change({ albumOrder: event.currentTarget.value as UserPreferences['albumOrder'] })}
				>
					<option value="newest">{t('preferencesCard.newestFirst')}</option>
					<option value="oldest">{t('preferencesCard.oldestFirst')}</option>
				</select>
			</label>
		</div>
		<div class="set-group">
			<h3>{t('preferencesCard.kindsOfMemories')}</h3>
			<div class="set-tiles">
				{#each memoryKinds as item (item.kind)}
					<label class="set-tile">
						<span>{t(item.label)}</span>
						<input
							type="checkbox"
							class="switch"
							checked={!(now.memoryKindsOff ?? []).includes(item.kind)}
							onchange={(event) => toggleKind(item.kind, event.currentTarget.checked)}
						/>
					</label>
				{/each}
			</div>
		</div>
		<div class="set-group">
			<h3>{t('preferencesCard.hiddenFromMemories')}</h3>
			{#if !hidden}
				<Skeleton height="40px" />
			{:else if hidden.count === 0 && hidden.people.length === 0}
				<p class="alb-meta">{t('preferencesCard.nothingHiddenFromMemories')}</p>
			{:else}
				{#each hidden.people as person (person.id)}
					<div class="set-row">
						<span>{person.name}</span>
						<Button small onclick={() => showPersonAgain(person.id)}
							>{t('preferencesCard.showAgain')}</Button
						>
					</div>
				{/each}
				{#if hidden.count > 0}
					<div class="set-row">
						<span>{t('preferencesCard.hiddenMemoryCount', { count: hidden.count })}</span>
						<Button small onclick={showAllAgain}>{t('preferencesCard.showAllAgain')}</Button>
					</div>
				{/if}
			{/if}
		</div>
		<div class="set-group">
			<h3>{t('preferencesCard.showInTheMenu')}</h3>
			<div class="set-tiles">
				{#each sections as section (section.path)}
					<label class="set-tile">
						<span>{t(section.label)}</span>
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
