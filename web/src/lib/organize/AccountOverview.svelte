<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AccountStats, type AssetList } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import { countUp } from '#lib/motion/actions.ts';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

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

<Card id="library" title={tr('Vaša biblioteka', 'Your library')}>
	{#if stats}
		<dl class="acct-stats">
			<div>
				<dt>{tr('Fotke', 'Photos')}</dt>
				<dd use:countUp={{ value: stats.photos }}></dd>
			</div>
			<div>
				<dt>{tr('Videi', 'Videos')}</dt>
				<dd use:countUp={{ value: stats.videos }}></dd>
			</div>
			<div>
				<dt>{tr('Albumi', 'Albums')}</dt>
				<dd use:countUp={{ value: stats.albums }}></dd>
			</div>
			<div>
				<dt>{tr('Favoriti', 'Favorites')}</dt>
				<dd use:countUp={{ value: stats.favorites }}></dd>
			</div>
			<div>
				<dt>{tr('Arhiva', 'Archive')}</dt>
				<dd use:countUp={{ value: stats.archived }}></dd>
			</div>
			<div>
				<dt>{tr('Smeće', 'Trash')}</dt>
				<dd use:countUp={{ value: stats.trashed }}></dd>
			</div>
			<div>
				<dt>{tr('Zauzeto', 'Used')}</dt>
				<dd
					use:countUp={{ value: stats.bytes, format: (value) => formatBytes(Math.round(value)) }}
				></dd>
			</div>
		</dl>
		{#if problems && problems.failed > 0}
			<p class="set-line acct-problems">
				<em class="set-chip err">{problems.failed}</em>
				{tr('datoteka se nije moglo obraditi.', 'files could not be processed.')}
				<button type="button" class="linkish" onclick={() => (showProblems = !showProblems)}>
					{showProblems ? tr('Sakrij', 'Hide') : tr('Prikaži', 'Show')}
				</button>
			</p>
			{#if showProblems}
				<div class="tbl-w">
					<table class="tbl">
						<tbody>
							{#each problems.items as asset (asset.id)}
								<tr>
									<td data-l={tr('Naziv', 'Name')}><b>{asset.originalName}</b></td>
									<td data-l={tr('Greška', 'Error')}>{asset.error ?? ''}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		{/if}
	{:else if failed}
		<p class="alb-meta">{tr('Podaci se ne mogu učitati.', 'This could not be loaded.')}</p>
	{:else}
		<Skeleton height="64px" />
	{/if}
</Card>
