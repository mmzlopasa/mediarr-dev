<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { api, familySource, type Family } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const POLL_MS = 15000;
	const source = familySource();

	let family = $state<Family>();
	let failed = $state(false);
	let timeline = $state<Timeline>();
	let title = $state('');
	let from = $state('');
	let to = $state('');
	let place = $state('');

	async function load() {
		try {
			family = await api.family();
			failed = false;
			await timeline?.refresh();
		} catch {
			failed = true;
		}
	}

	onMount(() => {
		load();
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	const open = $derived(family?.enabled && family.member);

	async function add(event: SubmitEvent) {
		event.preventDefault();
		try {
			await api.addFamilyRule(title, {
				from: from || undefined,
				to: to || undefined,
				place: place || undefined
			});
			title = from = to = place = '';
			await load();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
		}
	}

	async function remove(id: string) {
		try {
			await api.deleteFamilyRule(id);
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<svelte:head><title>{tr('Obitelj', 'Family')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{tr('Obitelj', 'Family')}</h1></div></div>

{#if failed}
	<Alert kind="err"
		>{tr(
			'Obiteljska biblioteka se nije učitala.',
			'The family library could not be loaded.'
		)}</Alert
	>
{:else if !family}
	<Skeleton height="200px" />
{:else if !open}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon="users"
				text={!family.enabled
					? tr(
							'Administrator nije uključio ovu značajku.',
							'An administrator has not turned this on.'
						)
					: tr('Još niste u obiteljskoj biblioteci.', 'You are not in the family library yet.')}
			/>
		</div>
	</section>
{:else}
	<Card title={tr('Što dijelim', 'What I share')}>
		<p class="alb-meta">
			{tr('Članovi: ', 'Members: ')}{family.members.map((member) => member.name).join(', ')}.
			{tr(
				'Ništa se ne dijeli dok ne postavite pravilo. Trezor se nikad ne dijeli.',
				'Nothing is shared until you set a rule. The vault is never shared.'
			)}
		</p>
		{#each family.rules as rule (rule.id)}
			<div class="alb-list">
				<b>{rule.title}</b>
				<Button small onclick={() => remove(rule.id)}
					>{tr('Prestani dijeliti', 'Stop sharing')}</Button
				>
			</div>
		{/each}
		<form class="form" onsubmit={add}>
			<Input label={tr('Naziv pravila', 'Rule name')} bind:value={title} />
			<Input label={tr('Od datuma', 'From date')} type="date" bind:value={from} />
			<Input label={tr('Do datuma', 'To date')} type="date" bind:value={to} />
			<Input label={tr('Mjesto', 'Place')} bind:value={place} />
			<Button type="submit" variant="gold" small
				>{tr('Dijeli s obitelji', 'Share with the family')}</Button
			>
		</form>
	</Card>
	<Timeline
		bind:this={timeline}
		{source}
		selectable={false}
		ownActions={false}
		hrefFor={(photo) => `${resolve('/(app)/family')}?photo=${photo}`}
		onOpen={(photo) => pushState('', { viewer: photo })}
	/>
	{#if page.state.viewer}
		<Viewer
			id={page.state.viewer}
			onClose={() => history.back()}
			onNavigate={(photo) => replaceState('', { viewer: photo })}
			onChanged={() => {}}
			neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
		/>
	{/if}
{/if}
