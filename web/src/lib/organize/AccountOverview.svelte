<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type AccountStats } from '#lib/api.ts';
	import Card from '#lib/design/components/Card.svelte';
	import { countUp } from '#lib/motion/actions.ts';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';

	let stats = $state<AccountStats>();
	let failed = $state(false);

	onMount(async () => {
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
	{:else if failed}
		<p class="alb-meta">{tr('Podaci se ne mogu učitati.', 'This could not be loaded.')}</p>
	{:else}
		<Skeleton height="64px" />
	{/if}
</Card>
