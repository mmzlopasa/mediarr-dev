<script lang="ts">
	import { api, formatBytes, type LibraryExport } from '#lib/api.ts';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, t } from '#lib/i18n.svelte.ts';
	import { EXPORT_STATUS, exportPct } from './exports.ts';

	let {
		entries,
		label,
		showOwner = false,
		onchange
	}: {
		entries: LibraryExport[] | undefined;
		label: string;
		showOwner?: boolean;
		onchange: () => void;
	} = $props();

	const when = (value: string) =>
		new Date(value).toLocaleString(lang(), { dateStyle: 'medium', timeStyle: 'short' });
	const day = (value: string) =>
		new Date(value).toLocaleDateString(lang(), { dateStyle: 'medium' });

	async function act(work: () => Promise<void>) {
		try {
			await work();
		} catch (cause) {
			showToast('err', (cause as Error).message);
		}
		onchange();
	}
</script>

{#if entries === undefined}
	<Skeleton height="56px" />
{:else if entries.length === 0}
	<p class="alb-meta">{t('export.none')}</p>
{:else}
	<ul class="set-list" aria-label={label}>
		{#each entries as entry (entry.id)}
			<li data-export={entry.status}>
				<span class="set-list-t">
					<b>{showOwner ? `${entry.userEmail} · ` : ''}{when(entry.createdAt)}</b>
					<small>
						<em class="set-chip {EXPORT_STATUS[entry.status].tone}"
							>{t(EXPORT_STATUS[entry.status].label)}</em
						>
						{t('export.progress', {
							done: entry.doneFiles,
							total: entry.totalFiles,
							doneBytes: formatBytes(entry.doneBytes),
							totalBytes: formatBytes(entry.totalBytes)
						})}
						{#if entry.startedByAdmin}
							· {t('export.startedBy', { name: entry.startedBy })}
						{/if}
					</small>
					{#if entry.status === 'running'}
						<Bar pct={exportPct(entry)} progress />
					{/if}
					{#if entry.missing > 0}
						<small>{t('export.missing', { count: entry.missing })}</small>
					{/if}
					{#if entry.status === 'failed' && entry.lastError}
						<small class="exp-err">{entry.lastError}</small>
					{/if}
					{#if entry.status === 'done'}
						{#if entry.expiresAt}
							<small>{t('export.keptUntil', { date: day(entry.expiresAt) })}</small>
						{/if}
						{#if entry.canDownload}
							<ul class="exp-parts" aria-label={t('export.parts')}>
								{#each entry.parts as part (part.number)}
									<li>
										<!-- eslint-disable svelte/no-navigation-without-resolve -- a file from the API, not a page -->
										<a
											class="btn sm"
											href="/api/exports/{entry.id}/parts/{part.number}"
											download
											data-sveltekit-reload>{t('export.part', { number: part.number })}</a
										>
										<!-- eslint-enable svelte/no-navigation-without-resolve -->
										<small
											>{formatBytes(part.size)} · {t('export.files', { count: part.files })}</small
										>
									</li>
								{/each}
							</ul>
						{:else}
							<small>{t('export.onlyOwnerDownloads')}</small>
						{/if}
					{/if}
				</span>
				<span class="imp-acts">
					{#if entry.status === 'running'}
						<Button small onclick={() => act(() => api.cancelExport(entry.id))}
							>{t('common.cancel')}</Button
						>
					{:else}
						<Button small variant="danger" onclick={() => act(() => api.removeExport(entry.id))}
							>{t('common.remove')}</Button
						>
					{/if}
				</span>
			</li>
		{/each}
	</ul>
{/if}

<style>
	.exp-parts {
		display: grid;
		gap: 6px;
		margin: 6px 0 0;
		padding: 0;
		list-style: none;
	}
	.exp-parts li {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 4px 10px;
		min-width: 0;
	}
	/* Every part's button one width, so the sizes beside them line up. */
	.exp-parts li > :global(.btn) {
		justify-content: center;
		min-width: 5.5rem;
	}
	.exp-parts small {
		color: var(--dim);
		font-size: 13px;
		font-variant-numeric: tabular-nums;
	}
	.exp-err {
		color: var(--err);
		overflow-wrap: anywhere;
	}
</style>
