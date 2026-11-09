<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AccountStats, type AssetList } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import { countUp } from '#lib/motion/actions.ts';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	let stats = $state<AccountStats>();
	let failed = $state(false);
	// Files the server could not read, kept here rather than over the photos.
	let problems = $state<AssetList>();
	let showProblems = $state(false);

	onMount(async () => {
		api
			.listProblems()
			.then((list) => (problems = list))
			.catch(() => undefined);
		try {
			stats = await api.myStats();
		} catch {
			failed = true;
		}
	});
</script>

<Card id="library" title={t('accountOverview.yourLibrary')}>
	{#if stats}
		<dl class="acct-stats">
			<div>
				<dt>{t('common.photos')}</dt>
				<dd use:countUp={{ value: stats.photos }}></dd>
			</div>
			<div>
				<dt>{t('common.videos')}</dt>
				<dd use:countUp={{ value: stats.videos }}></dd>
			</div>
			<div>
				<dt>{t('accountOverview.albums')}</dt>
				<dd use:countUp={{ value: stats.albums }}></dd>
			</div>
			<div>
				<dt>{t('accountOverview.favorites')}</dt>
				<dd use:countUp={{ value: stats.favorites }}></dd>
			</div>
			<div>
				<dt>{t('accountOverview.archive')}</dt>
				<dd use:countUp={{ value: stats.archived }}></dd>
			</div>
			<div>
				<dt>{t('accountOverview.trash')}</dt>
				<dd use:countUp={{ value: stats.trashed }}></dd>
			</div>
			<div>
				<dt>{t('accountOverview.used')}</dt>
				<dd
					use:countUp={{ value: stats.bytes, format: (value) => formatBytes(Math.round(value)) }}
				></dd>
			</div>
		</dl>
		{#if problems && problems.failed > 0}
			<p class="set-line acct-problems">
				<em class="set-chip err">{problems.failed}</em>
				{t('accountOverview.filesCouldNotBeProcessed')}
				<button type="button" class="linkish" onclick={() => (showProblems = !showProblems)}>
					{showProblems ? t('common.hide') : t('common.show')}
				</button>
			</p>
			{#if showProblems}
				<div class="tbl-w">
					<table class="tbl">
						<tbody>
							{#each problems.items as asset (asset.id)}
								<tr>
									<td data-l={t('common.name')}><b>{asset.originalName}</b></td>
									<td data-l={t('accountOverview.error')}>{asset.error ?? ''}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		{/if}
	{:else if failed}
		<p class="alb-meta">{t('common.thisCouldNotBeLoaded')}</p>
	{:else}
		<Skeleton height="64px" />
	{/if}
</Card>
