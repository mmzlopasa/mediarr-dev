<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import type { PageProps } from './$types';
	import Viewer from '#lib/timeline/Viewer.svelte';

	let { params }: PageProps = $props();
</script>

<Viewer
	id={params.id}
	onClose={() => goto(resolve('/(app)'))}
	onNavigate={(id) => goto(resolve('/(app)/photos/[id]', { id }), { replaceState: true })}
	onChanged={() => {}}
/>
