<script lang="ts">
	import SectionPage from '#lib/design/components/SectionPage.svelte';
	import type { PageProps } from './$types';

	let { data }: PageProps = $props();
</script>

<SectionPage item={data.item} suffix="Mediarr Admin" />
