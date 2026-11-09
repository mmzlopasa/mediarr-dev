<script lang="ts">
	import { memoryTitle } from '#lib/organize/memories.ts';
	import { onMount } from 'svelte';
	import { api, type Memory } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import Story from '#lib/organize/Story.svelte';

	const item = appNav.find((candidate) => candidate.path === '/memories') ?? appNav[0];

	let memories = $state<Memory[]>();
	let failed = $state(false);
	let open = $state<Memory>();

	// The person's own date decides what today is, not the server's.
	function today() {
		const now = new Date();
		const month = String(now.getMonth() + 1).padStart(2, '0');
		const day = String(now.getDate()).padStart(2, '0');
		return `${now.getFullYear()}-${month}-${day}`;
	}

	onMount(async () => {
		try {
			memories = await api.memories(today());
		} catch {
			failed = true;
		}
	});

	const titleOf = (memory: Memory) => memoryTitle(memory);
</script>

<svelte:head><title>{t(item.label)} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t(item.label)}</h1></div></div>

{#if failed}
	<Alert kind="err">{t('memories.memoriesCouldNotBeLoaded')}</Alert>
{:else if !memories}
	<div class="alb-grid" aria-hidden="true">
		<Skeleton height="220px" /><Skeleton height="220px" />
	</div>
{:else if memories.length === 0}
	<section class="card glass">
		<div class="card-b"><EmptyState icon={item.icon} text={item.empty ? t(item.empty) : ''} /></div>
	</section>
{:else}
	<div class="stories stories-page">
		{#each memories as memory (memory.kind + memory.title)}
			<button type="button" class="story-tile" onclick={() => (open = memory)}>
				<img src="/api/assets/{memory.items[0].id}/thumbnail" alt="" loading="lazy" />
				<span class="story-tile-t">
					<b>{titleOf(memory)}</b>
					<small>{memory.title} · {memory.items.length}</small>
				</span>
			</button>
		{/each}
	</div>
{/if}

{#if open}
	<Story memory={open} title={titleOf(open)} onClose={() => (open = undefined)} />
{/if}
