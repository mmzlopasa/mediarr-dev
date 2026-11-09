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
	import { t } from '#lib/i18n.svelte.ts';
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
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		}
	}

	async function remove(id: string) {
		try {
			await api.deleteFamilyRule(id);
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<svelte:head><title>{t('family.family')} — Mediarr</title></svelte:head>

<div class="ph"><div><h1>{t('family.family')}</h1></div></div>

{#if failed}
	<Alert kind="err">{t('family.theFamilyLibraryCouldNot')}</Alert>
{:else if !family}
	<Skeleton height="200px" />
{:else if !open}
	<section class="card glass">
		<div class="card-b">
			<EmptyState
				icon="users"
				text={!family.enabled
					? t('family.anAdministratorHasNotTurned')
					: t('family.youAreNotInThe')}
			/>
		</div>
	</section>
{:else}
	<Card title={t('family.whatIShare')}>
		<p class="alb-meta">
			{t('family.members')}{family.members.map((member) => member.name).join(', ')}.
			{t('family.nothingIsSharedUntilYou')}
		</p>
		{#each family.rules as rule (rule.id)}
			<div class="alb-list">
				<b>{rule.title}</b>
				<Button small onclick={() => remove(rule.id)}>{t('family.stopSharing')}</Button>
			</div>
		{/each}
		<form class="form" onsubmit={add}>
			<Input label={t('family.ruleName')} bind:value={title} />
			<Input label={t('common.fromDate')} type="date" bind:value={from} />
			<Input label={t('common.toDate')} type="date" bind:value={to} />
			<Input label={t('common.place')} bind:value={place} />
			<Button type="submit" variant="gold" small>{t('family.shareWithTheFamily')}</Button>
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
			playlist={(photo) => timeline?.playlist(photo) ?? Promise.resolve([])}
		/>
	{/if}
{/if}
