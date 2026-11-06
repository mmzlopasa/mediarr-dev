<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type UserSession } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { describeAgent, since } from './agent.ts';

	// The most recent few are what people look for; the rest are one click away.
	const FIRST = 5;

	let sessions = $state<UserSession[]>();
	let failed = $state(false);
	let all = $state(false);

	const sorted = $derived(
		[...(sessions ?? [])].sort(
			(a, b) => Number(b.current) - Number(a.current) || b.lastSeenAt.localeCompare(a.lastSeenAt)
		)
	);
	const shown = $derived(all ? sorted : sorted.slice(0, FIRST));

	async function load() {
		try {
			sessions = await api.mySessions();
			failed = false;
		} catch {
			failed = true;
		}
	}

	async function act(work: () => Promise<unknown>) {
		try {
			await work();
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	function title(session: UserSession) {
		const agent = describeAgent(session.userAgent);
		if (agent.program && agent.system)
			return tr(`${agent.program} na ${agent.system}`, `${agent.program} on ${agent.system}`);
		return agent.program || agent.system || tr('Nepoznat uređaj', 'Unknown device');
	}

	onMount(load);
</script>

<Card
	id="devices"
	title={tr('Prijavljeni uređaji', 'Signed-in devices')}
	note={sessions
		? tr(
				`${sessions.length} prijava`,
				sessions.length === 1 ? '1 session' : `${sessions.length} sessions`
			)
		: undefined}
>
	{#snippet actions()}
		{#if sessions && sessions.length > 1}
			<Button small onclick={() => act(() => api.endOtherSessions())}>
				{tr('Odjavi sve ostale', 'Sign out all the others')}
			</Button>
		{/if}
	{/snippet}
	{#if sessions}
		<ul class="set-list">
			{#each shown as session (session.id)}
				<li>
					<span class="set-list-ic"
						><Icon name={describeAgent(session.userAgent).phone ? 'phone' : 'monitor'} /></span
					>
					<span class="set-list-t">
						<b title={session.userAgent}>{title(session)}</b>
						<small>
							{#if session.current}<em class="set-chip ok">{tr('Ovaj uređaj', 'This device')}</em
								>{/if}
							{#if session.ip}<span class="mono">{session.ip}</span> ·{/if}
							<time
								datetime={session.lastSeenAt}
								title={new Date(session.lastSeenAt).toLocaleString()}
								>{since(new Date(session.lastSeenAt))}</time
							>
						</small>
					</span>
					{#if !session.current}
						<Button small onclick={() => act(() => api.endSession(session.id))}>
							{tr('Odjavi', 'Sign out')}
						</Button>
					{/if}
				</li>
			{/each}
		</ul>
		{#if sorted.length > FIRST}
			<button type="button" class="set-more" onclick={() => (all = !all)}>
				{all
					? tr('Prikaži manje', 'Show fewer')
					: tr(`Prikaži sve (${sorted.length})`, `Show all ${sorted.length}`)}
			</button>
		{/if}
	{:else if failed}
		<p class="alb-meta">{tr('Podaci se ne mogu učitati.', 'This could not be loaded.')}</p>
	{:else}
		<Skeleton height="72px" />
	{/if}
</Card>
