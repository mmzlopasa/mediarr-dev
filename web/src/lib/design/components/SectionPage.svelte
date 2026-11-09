<script lang="ts">
	import { t } from '#lib/i18n.svelte.ts';
	import type { NavItem } from '#lib/nav.ts';
	import EmptyState from './EmptyState.svelte';

	let { item, suffix = 'Mediarr' }: { item: NavItem; suffix?: string } = $props();
</script>

<svelte:head><title>{t(item.label)} — {suffix}</title></svelte:head>

<div class="ph">
	<div><h1>{t(item.label)}</h1></div>
</div>
<section class="card glass">
	<div class="card-b">
		<EmptyState icon={item.icon} text={item.empty ? t(item.empty) : ''} />
	</div>
</section>
