<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import EmptyState from './EmptyState.svelte';

	let { item, suffix = 'Mediarr' }: { item: NavItem; suffix?: string } = $props();
</script>

<svelte:head><title>{tr(item.hr, item.en)} — {suffix}</title></svelte:head>

<div class="ph">
	<div><h1>{tr(item.hr, item.en)}</h1></div>
</div>
<section class="card glass">
	<div class="card-b">
		<EmptyState icon={item.icon} text={tr(item.emptyHr, item.emptyEn)} />
	</div>
</section>
