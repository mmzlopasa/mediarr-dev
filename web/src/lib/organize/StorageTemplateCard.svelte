<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type StoragePreview, type StorageTemplate } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	/** How originals are laid out on the disk, inside each user's folder. */
	let current = $state<StorageTemplate>();
	let draft = $state('');
	let previews = $state<StoragePreview[]>([]);
	let previewError = $state('');
	let field = $state<HTMLInputElement>();
	let timer: ReturnType<typeof setTimeout> | undefined;
	let poll: ReturnType<typeof setInterval> | undefined;

	const report = $derived(current?.report);
	const saved = $derived((current?.template ?? '') === draft.trim());
	// Moving for real comes only after a dry run of this very template.
	const tried = $derived(
		Boolean(
			report &&
			report.dryRun &&
			!report.running &&
			report.template === current?.template &&
			current?.template
		)
	);

	async function load() {
		current = await api.storageTemplate();
		if (current.report?.running) {
			poll ??= setInterval(load, 1500);
		} else {
			clearInterval(poll);
			poll = undefined;
		}
	}

	onMount(() => {
		load()
			.then(() => {
				draft = current?.template ?? '';
				preview();
			})
			.catch(() => showToast('err', tr('Nije učitano.', 'Not loaded.')));
		return () => {
			clearTimeout(timer);
			clearInterval(poll);
		};
	});

	function preview() {
		clearTimeout(timer);
		timer = setTimeout(async () => {
			try {
				previews = await api.previewStorageTemplate(draft.trim());
				previewError = '';
			} catch (cause) {
				previews = [];
				previewError = cause instanceof Error ? cause.message : '';
			}
		}, 300);
	}

	function insert(token: string) {
		const at = field?.selectionStart ?? draft.length;
		draft = draft.slice(0, at) + token + draft.slice(at);
		preview();
		field?.focus();
	}

	async function save(template: string) {
		try {
			current = await api.setStorageTemplate(template);
			draft = current.template;
			preview();
			showToast('ok', tr('Spremljeno.', 'Saved.'));
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije spremljeno.', 'Not saved.')
			);
		}
	}

	async function apply(dryRun: boolean) {
		if (
			!dryRun &&
			!confirm(
				tr(
					`Premjestiti ${report?.moved ?? 0} datoteka na nova mjesta? Originali se ne mijenjaju, samo mjesto na disku.`,
					`Move ${report?.moved ?? 0} files to their new places? The originals do not change, only where they are on the disk.`
				)
			)
		)
			return;
		try {
			await api.applyStorageTemplate(dryRun);
			setTimeout(load, 500);
			poll ??= setInterval(load, 1500);
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije pokrenuto.', 'Not started.')
			);
		}
	}
</script>

<Card id="storage-template" title={tr('Predložak pohrane', 'Storage template')}>
	{#if !current}
		<Skeleton height="140px" />
	{:else}
		<p class="alb-meta">
			{tr(
				'Kako se originali slažu na disku, unutar mape svakog korisnika. Vrijedi za nove datoteke; postojeće se premještaju tek kad to zatražite, nakon probnog prolaza. Vanjska biblioteka se nikad ne premješta.',
				'How originals are laid out on the disk, inside each user’s folder. It applies to new files; the ones already here move only when you ask, after a dry run. An external library never moves.'
			)}
		</p>
		<label class="st-field">
			<span>{tr('Predložak', 'Template')}</span>
			<input
				class="in mono"
				bind:this={field}
				bind:value={draft}
				oninput={preview}
				placeholder={current.defaultLayout}
				aria-label={tr('Predložak', 'Template')}
				maxlength="200"
			/>
		</label>
		<div class="st-tokens" role="group" aria-label={tr('Polja', 'Fields')}>
			{#each current.tokens as token (token.token)}
				<button
					type="button"
					class="st-token"
					title={token.means}
					onclick={() => insert(token.token)}>{token.token}</button
				>
			{/each}
		</div>
		{#if previewError}
			<p class="st-error" role="alert">{previewError}</p>
		{:else if previews.length}
			<ul class="st-previews" aria-label={tr('Primjeri', 'Examples')}>
				{#each previews as example, n (n)}
					<li><span>{example.name}</span><b class="mono">{example.path}</b></li>
				{/each}
			</ul>
		{/if}
		<div class="set-foot st-foot">
			{#if current.template}
				<Button small onclick={() => save('')}>{tr('Kao prije', 'Back to the usual layout')}</Button
				>
			{/if}
			<Button
				variant="gold"
				small
				disabled={saved || Boolean(previewError)}
				onclick={() => save(draft)}>{tr('Spremi', 'Save')}</Button
			>
		</div>

		{#if current.template}
			<div class="st-apply">
				<h3>{tr('Datoteke koje su već ovdje', 'Files already here')}</h3>
				{#if report?.running}
					<p role="status">
						{report.dryRun ? tr('Probni prolaz…', 'Dry run…') : tr('Premještam…', 'Moving…')}
						{report.checked}
					</p>
				{:else if report && report.template === current.template}
					<p role="status">
						{#if report.dryRun}
							{tr(
								`Probni prolaz: premjestilo bi se ${report.moved} od ${report.checked}.`,
								`Dry run: ${report.moved} of ${report.checked} would move.`
							)}
						{:else}
							{tr(
								`Premješteno ${report.moved} od ${report.checked}.`,
								`Moved ${report.moved} of ${report.checked}.`
							)}
						{/if}
						{#if report.failed}
							{tr(`Nije uspjelo: ${report.failed}.`, `Failed: ${report.failed}.`)}
						{/if}
					</p>
					{#if report.samples.length}
						<ul class="st-previews" aria-label={tr('Što se premješta', 'What moves')}>
							{#each report.samples.slice(0, 10) as move, n (n)}
								<li><span class="mono">{move.from}</span><b class="mono">{move.to}</b></li>
							{/each}
						</ul>
					{/if}
					{#each report.errors as problem, n (n)}<p class="st-error">{problem}</p>{/each}
				{/if}
				<div class="set-foot st-foot">
					<Button small disabled={report?.running || !saved} onclick={() => apply(true)}
						>{tr('Probni prolaz', 'Dry run')}</Button
					>
					<Button
						variant="gold"
						small
						disabled={!tried || report?.running || !report?.moved}
						onclick={() => apply(false)}>{tr('Premjesti datoteke', 'Move the files')}</Button
					>
				</div>
			</div>
		{/if}
	{/if}
</Card>
