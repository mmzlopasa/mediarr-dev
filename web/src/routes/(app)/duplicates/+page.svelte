<script lang="ts">
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
	import { tr } from '#lib/i18n.svelte.ts';

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

	$effect(() => {
		load();
		const timer = setInterval(load, data?.resolving ? BUSY_POLL_MS : POLL_MS);
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
			showToast('ok', tr('Riješeno. Kopije su u smeću.', 'Resolved. The copies are in the trash.'));
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		} finally {
			working = false;
		}
	}

	async function previewAll(exactOnly: boolean) {
		try {
			const result = await api.resolveDuplicates({ all: true, exactOnly, dryRun: true });
			all = { exactOnly, result };
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
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
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		} finally {
			working = false;
		}
	}

	async function dismiss(group: DuplicateGroup) {
		try {
			await api.dismissDuplicates(group.items.map((item) => item.id));
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr('Duplikati', 'Duplicates')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr('Duplikati', 'Duplicates')}</h1></div></div>

{#if failed}
	<Alert kind="err">{tr('Duplikati se nisu učitali.', 'Duplicates could not be loaded.')}</Alert>
{:else if !data}
	<Skeleton height="200px" />
{:else}
	{#if data.pending > 0}
		<Alert kind="warn"
			>{tr(
				`Još se uspoređuje fotki: ${data.pending}.`,
				`Photos still being compared: ${data.pending}.`
			)}</Alert
		>
	{/if}
	{#if data.resolving}
		<section class="card glass dup-progress" aria-live="polite">
			<div class="card-b">
				<b
					>{tr(
						`Rješavam duplikate: ${data.resolving.done} od ${data.resolving.total}`,
						`Resolving duplicates: ${data.resolving.done} of ${data.resolving.total}`
					)}</b
				>
				<progress max={data.resolving.total} value={data.resolving.done}></progress>
			</div>
		</section>
	{/if}
	{#if data.groups.length === 0}
		<section class="card glass">
			<div class="card-b">
				<EmptyState
					icon="copy"
					text={tr('Nisu pronađene slične fotke.', 'No similar photos were found.')}
				/>
			</div>
		</section>
	{:else}
		<p class="dup-note">
			{tr(
				`Ovo su samo prijedlozi. Ništa se ne briše bez vaše potvrde, a obrisano ostaje ${trashDays()} dana u smeću.`,
				`These are only proposals. Nothing is removed without your confirmation, and what is removed stays in the trash for ${trashDays()} days.`
			)}
			{#if data.total > data.groups.length}
				{tr(
					`Prikazano ${data.groups.length} od ${data.total}.`,
					`Showing ${data.groups.length} of ${data.total}.`
				)}
			{/if}
		</p>
		{#if !data.resolving}
			<div class="dup-all">
				{#if (data.exactTotal ?? 0) > 0}
					<Button onclick={() => previewAll(true)}
						>{tr(
							`Riješi iste (${data.exactTotal})`,
							`Resolve the identical (${data.exactTotal})`
						)}</Button
					>
				{/if}
				<Button variant="gold" onclick={() => previewAll(false)}
					>{tr(
						`Riješi sve po prijedlogu (${data.total})`,
						`Resolve all as proposed (${data.total})`
					)}</Button
				>
			</div>
		{/if}
		{#each data.groups as group (group.items[0].id)}
			<section class="card glass dup-group">
				<div class="card-b">
					<p class="dup-head">
						<span class="dup-kind" class:exact={group.exact}
							>{group.exact ? tr('Ista slika', 'Same picture') : tr('Slične', 'Alike')}</span
						>
						<span
							>{tr('Predlažem zadržati', 'Proposed to keep')}: {reasonOf(group, tr)} · {tr(
								'oslobađa',
								'frees'
							)}
							{formatBytes(group.freedBytes)}</span
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
										{tr('Zadrži', 'Keep')}{:else}<Icon name="trash" size={14} />
										{tr('U smeće', 'To trash')}{/if}
								</span>
								<b>{item.originalName}</b>
								<small>
									{#if item.width && item.height}{item.width} × {item.height} ·
									{/if}{formatBytes(item.sizeBytes)}
								</small>
								{#if notesOf(item, tr).length}
									<span class="dup-notes">
										{#each notesOf(item, tr) as note (note)}<i>{note}</i>{/each}
									</span>
								{/if}
							</button>
						{/each}
					</div>
					<div class="dup-actions">
						<Button onclick={() => dismiss(group)}>{tr('Nisu duplikati', 'Not duplicates')}</Button>
						<Button
							variant="danger"
							disabled={toTrash(group).length === 0 || toTrash(group).length === group.items.length}
							onclick={() => (confirming = group)}
						>
							{tr(
								`Riješi (${toTrash(group).length} u smeće)`,
								`Resolve (${toTrash(group).length} to the trash)`
							)}
						</Button>
					</div>
				</div>
			</section>
		{/each}
	{/if}
{/if}

<Dialog
	title={tr('Riješiti ovu grupu?', 'Resolve this group?')}
	bind:open={() => confirming !== undefined, (open) => !open && (confirming = undefined)}
>
	<p>
		{tr(
			`Zadržana fotka preuzima albume, oznake, favorit, opis, ocjenu, lokaciju i imena osoba od ostalih. One idu u smeće na ${trashDays()} dana i mogu se vratiti.`,
			`The kept photo takes over the albums, tags, favorite, description, rating, location and names of people from the others. They go to the trash for ${trashDays()} days and can be restored.`
		)}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirming = undefined)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" disabled={working} onclick={resolve}>{tr('Riješi', 'Resolve')}</Button>
	{/snippet}
</Dialog>

<Dialog
	title={all?.exactOnly
		? tr('Riješiti sve iste slike?', 'Resolve every identical picture?')
		: tr('Riješiti sve duplikate?', 'Resolve all duplicates?')}
	bind:open={() => all !== undefined, (open) => !open && (all = undefined)}
>
	{#if all}
		<p>
			{tr(
				`Grupa: ${all.result.groups}. U smeće ide ${all.result.trashed} fotki, što oslobađa ${formatBytes(all.result.freedBytes)} kad se smeće isprazni.`,
				`Groups: ${all.result.groups}. ${all.result.trashed} photos go to the trash, which frees ${formatBytes(all.result.freedBytes)} once it is emptied.`
			)}
		</p>
		<p>
			{tr(
				`U svakoj grupi ostaje predložena fotka i preuzima ono što su imale ostale. Sve ostaje u smeću ${trashDays()} dana i može se vratiti.`,
				`In each group the proposed photo stays and takes over what the others had. Everything stays in the trash for ${trashDays()} days and can be restored.`
			)}
		</p>
	{/if}
	{#snippet footer()}
		<Button onclick={() => (all = undefined)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" disabled={working} onclick={resolveAll}
			>{tr('Riješi sve', 'Resolve all')}</Button
		>
	{/snippet}
</Dialog>
