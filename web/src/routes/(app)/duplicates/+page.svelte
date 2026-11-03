<script lang="ts">
	import { api, formatBytes, type DuplicateGroup, type Duplicates } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	const POLL_MS = 10000;

	let data = $state<Duplicates>();
	let failed = $state(false);
	// What the user changed by hand. Everything else follows the proposal.
	let choices = $state<Record<string, boolean>>({});
	let confirming = $state<DuplicateGroup>();

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
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	const keeps = (group: DuplicateGroup, id: string) => choices[id] ?? id === group.keepId;
	const toTrash = (group: DuplicateGroup) =>
		group.items.filter((item) => !keeps(group, item.id)).map((item) => item.id);

	async function trash() {
		if (!confirming) return;
		const ids = toTrash(confirming);
		try {
			await api.bulk(ids, 'delete');
			confirming = undefined;
			showToast('ok', tr('Premješteno u smeće.', 'Moved to the trash.'));
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
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
				'Ovo su samo prijedlozi. Ništa se ne briše bez vaše potvrde, a obrisano ostaje 30 dana u smeću.',
				'These are only proposals. Nothing is removed without your confirmation, and what is removed stays in the trash for 30 days.'
			)}
			{#if data.total > data.groups.length}
				{tr(
					`Prikazano ${data.groups.length} od ${data.total}.`,
					`Showing ${data.groups.length} of ${data.total}.`
				)}
			{/if}
		</p>
		{#each data.groups as group (group.items[0].id)}
			<section class="card glass dup-group">
				<div class="card-b">
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
								`Premjesti u smeće (${toTrash(group).length})`,
								`Move to the trash (${toTrash(group).length})`
							)}
						</Button>
					</div>
				</div>
			</section>
		{/each}
	{/if}
{/if}

<Dialog
	title={tr('Premjestiti u smeće?', 'Move to the trash?')}
	bind:open={() => confirming !== undefined, (open) => !open && (confirming = undefined)}
>
	<p>
		{tr(
			'Odabrane fotke ostaju u smeću 30 dana i mogu se vratiti.',
			'The selected photos stay in the trash for 30 days and can be restored.'
		)}
	</p>
	{#snippet footer()}
		<Button onclick={() => (confirming = undefined)}>{tr('Odustani', 'Cancel')}</Button>
		<Button variant="danger" onclick={trash}>{tr('Premjesti', 'Move')}</Button>
	{/snippet}
</Dialog>
