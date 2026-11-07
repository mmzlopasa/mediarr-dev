<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type UpgradeSnapshot } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	/** Snapshots of the database made before upgrades; going back is a command, with the server off. */
	let snapshots = $state<UpgradeSnapshot[]>();

	onMount(async () => {
		snapshots = await api.upgradeSnapshots().catch(() => []);
	});

	async function remove(snap: UpgradeSnapshot) {
		const ask = tr(
			'Obrisati ovu snimku? Na nju se više neće moći vratiti.',
			'Delete this snapshot? It will no longer be possible to go back to it.'
		);
		if (!confirm(ask)) return;
		try {
			await api.deleteUpgradeSnapshot(snap.name);
			snapshots = snapshots?.filter((entry) => entry.name !== snap.name);
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Nije obrisano.', 'Not deleted.')
			);
		}
	}
</script>

<Card id="snapshots" title={tr('Snimke prije nadogradnje', 'Snapshots before upgrades')}>
	<p class="alb-meta">
		{tr(
			'Prije svake nadogradnje koja mijenja bazu Mediarr sam spremi snimku baze. Čuvaju se zadnje tri.',
			'Before each upgrade that changes the database, Mediarr keeps a snapshot of it. The last three are kept.'
		)}
	</p>
	{#if snapshots === undefined}
		<Skeleton height="56px" />
	{:else if snapshots.length === 0}
		<p class="alb-meta">
			{tr(
				'Još nema snimki. Prva nastaje pri sljedećoj nadogradnji koja mijenja bazu.',
				'No snapshots yet. The first is made at the next upgrade that changes the database.'
			)}
		</p>
	{:else}
		<ul class="set-list" aria-label={tr('Snimke prije nadogradnje', 'Snapshots before upgrades')}>
			{#each snapshots as snap (snap.name)}
				<li data-snapshot={snap.name}>
					<span class="set-list-t">
						<b>{snap.fromVersion || tr('ranija verzija', 'earlier version')} → {snap.toVersion}</b>
						<small>
							<time datetime={snap.createdAt}>{new Date(snap.createdAt).toLocaleString()}</time>
							· {formatBytes(snap.sizeBytes)} · <span class="mono">{snap.name}</span>
						</small>
					</span>
					<Button small variant="danger" onclick={() => remove(snap)}
						>{tr('Obriši', 'Delete')}</Button
					>
				</li>
			{/each}
		</ul>
		<p class="alb-meta">
			{tr(
				'Povratak na zadnju snimku, u mapi s docker-compose.yml:',
				'To go back to the newest one, in the folder with docker-compose.yml:'
			)}
		</p>
		<pre class="snap-cmd"><code
				>docker compose stop server worker
docker compose run --rm server rollback</code
			></pre>
	{/if}
</Card>
