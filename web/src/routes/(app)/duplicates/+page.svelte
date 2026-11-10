<script lang="ts">
	import { onMount } from 'svelte';
	import { trashDays } from '#lib/preferences.svelte.ts';
	import {
		api,
		formatBytes,
		type DuplicateGroup,
		type DuplicateResolveResult,
		type Duplicates
	} from '#lib/api.ts';
	import { choiceOf, notesOf, reasonOf } from '#lib/organize/duplicates.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	const POLL_MS = 10000;
	const BUSY_POLL_MS = 1500;

	let data = $state<Duplicates>();
	let failed = $state(false);
	// What the user changed by hand. Everything else follows the proposal.
	let choices = $state<Record<string, boolean>>({});
	let confirming = $state<DuplicateGroup>();
	// Resolving every group: what it would do, before it is confirmed.
	let all = $state<{ exactOnly: boolean; result: DuplicateResolveResult }>();
	let working = $state(false);

	async function load() {
		try {
			data = await api.duplicates();
			failed = false;
		} catch {
			failed = true;
		}
	}

	// Asked once, then again on a timer: quicker while groups are being resolved. The timer only
	// follows whether that is so, so a new answer does not ask again at once.
	const busy = $derived(Boolean(data?.resolving));
	onMount(load);
	$effect(() => {
		const timer = setInterval(load, busy ? BUSY_POLL_MS : POLL_MS);
		return () => clearInterval(timer);
	});

	const keeps = (group: DuplicateGroup, id: string) => choices[id] ?? id === group.keepId;
	const toTrash = (group: DuplicateGroup) =>
		group.items.filter((item) => !keeps(group, item.id)).map((item) => item.id);

	async function resolve() {
		if (!confirming) return;
		const group = confirming;
		const choice = choiceOf(group, (id) => keeps(group, id));
		if (!choice) return;
		working = true;
		try {
			await api.resolveDuplicates({ groups: [choice] });
			confirming = undefined;
			showToast('ok', t('duplicates.resolvedTheCopiesAreIn'));
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		} finally {
			working = false;
		}
	}

	async function previewAll(exactOnly: boolean) {
		try {
			const result = await api.resolveDuplicates({ all: true, exactOnly, dryRun: true });
			all = { exactOnly, result };
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function resolveAll() {
		if (!all) return;
		working = true;
		try {
			await api.resolveDuplicates({ all: true, exactOnly: all.exactOnly });
			all = undefined;
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		} finally {
			working = false;
		}
	}

	async function dismiss(group: DuplicateGroup) {
		try {
			await api.dismissDuplicates(group.items.map((item) => item.id));
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t('duplicates.duplicates')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t('duplicates.duplicates')}</h1></div></div>

{#if failed}
	<Alert kind="err">{t('duplicates.duplicatesCouldNotBeLoaded')}</Alert>
{:else if !data}
	<Skeleton height="200px" />
{:else}
	{#if data.pending > 0}
		<Alert kind="warn"
			>{t('duplicates.photosStillBeingComparedPending', { pending: data.pending })}</Alert
		>
	{/if}
	{#if data.resolving}
		<section class="card glass dup-progress" aria-live="polite">
			<div class="card-b">
				<b
					>{t('duplicates.resolvingDuplicatesDoneOfTotal', {
						done: data.resolving.done,
						total: data.resolving.total
					})}</b
				>
				<progress max={data.resolving.total} value={data.resolving.done}></progress>
			</div>
		</section>
	{/if}
	{#if data.groups.length === 0}
		<section class="card glass">
			<div class="card-b">
				<EmptyState icon="copy" text={t('duplicates.noSimilarPhotosWereFound')} />
			</div>
		</section>
	{:else}
		<p class="dup-note">
			{t('duplicates.theseAreOnlyProposalsNothing', { trashDays: trashDays() })}
			{#if data.total > data.groups.length}
				{t('duplicates.showingGroupscountOfTotal', {
					groupsCount: data.groups.length,
					total: data.total
				})}
			{/if}
		</p>
		{#if !data.resolving}
			<div class="dup-all">
				{#if (data.exactTotal ?? 0) > 0}
					<Button onclick={() => previewAll(true)}
						>{t('duplicates.resolveTheIdenticalExacttotal', {
							exactTotal: data.exactTotal
						})}</Button
					>
				{/if}
				<Button variant="gold" onclick={() => previewAll(false)}
					>{t('duplicates.resolveAllAsProposedTotal', { total: data.total })}</Button
				>
			</div>
		{/if}
		{#each data.groups as group (group.items[0].id)}
			<section class="card glass dup-group">
				<div class="card-b">
					<p class="dup-head">
						<span class="dup-kind" class:exact={group.exact}
							>{group.exact ? t('duplicates.samePicture') : t('duplicates.alike')}</span
						>
						<span
							>{t('duplicates.proposedToKeep')}: {reasonOf(group)} · {t('duplicates.frees')}
							<span class="dup-bytes">{formatBytes(group.freedBytes)}</span></span
						>
					</p>
					<div class="dup-grid">
						{#each group.items as item (item.id)}
							<button
								type="button"
								class="dup-item"
								class:on={keeps(group, item.id)}
								aria-pressed={keeps(group, item.id)}
								onclick={() => (choices[item.id] = !keeps(group, item.id))}
							>
								<img src="/api/assets/{item.id}/thumbnail" alt={item.originalName} />
								<span class="dup-state">
									{#if keeps(group, item.id)}<Icon name="check" size={14} />
										{t('duplicates.keep')}{:else}<Icon name="trash" size={14} />
										{t('duplicates.toTrash')}{/if}
								</span>
								<b>{item.originalName}</b>
								<small>
									{[
										item.width && item.height ? `${item.width} × ${item.height}` : '',
										formatBytes(item.sizeBytes)
									]
										.filter(Boolean)
										.join(' · ')}
								</small>
								{#if notesOf(item).length}
									<span class="dup-notes">
										{#each notesOf(item) as note (note)}<i>{note}</i>{/each}
									</span>
								{/if}
							</button>
						{/each}
					</div>
					<div class="dup-actions">
						<Button onclick={() => dismiss(group)}>{t('duplicates.notDuplicates')}</Button>
						<Button
							variant="danger"
							disabled={toTrash(group).length === 0 || toTrash(group).length === group.items.length}
							onclick={() => (confirming = group)}
						>
							{t('duplicates.resolveTotrashToTheTrash', { toTrash: toTrash(group).length })}
						</Button>
					</div>
				</div>
			</section>
		{/each}
	{/if}
{/if}

<Dialog
	title={t('duplicates.resolveThisGroup')}
	bind:open={() => confirming !== undefined, (open) => !open && (confirming = undefined)}
>
	<p>
		{t('duplicates.theKeptPhotoTakesOver', { trashDays: trashDays() })}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirming = undefined)}>{t('common.cancel')}</Button>
		<Button variant="danger" disabled={working} onclick={resolve}>{t('duplicates.resolve')}</Button>
	{/snippet}
</Dialog>

<Dialog
	title={all?.exactOnly
		? t('duplicates.resolveEveryIdenticalPicture')
		: t('duplicates.resolveAllDuplicates')}
	bind:open={() => all !== undefined, (open) => !open && (all = undefined)}
>
	{#if all}
		<p>
			{t('duplicates.groupsGroupsTrashedPhotosGo', {
				groups: all.result.groups,
				trashed: all.result.trashed,
				formatBytes: formatBytes(all.result.freedBytes)
			})}
		</p>
		<p>
			{t('duplicates.inEachGroupTheProposed', { trashDays: trashDays() })}
		</p>
	{/if}
	{#snippet footer()}
		<Button onclick={() => (all = undefined)}>{t('common.cancel')}</Button>
		<Button variant="danger" disabled={working} onclick={resolveAll}
			>{t('duplicates.resolveAll')}</Button
		>
	{/snippet}
</Dialog>
