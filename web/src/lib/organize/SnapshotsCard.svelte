<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type UpgradeSnapshot } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { dateLocale, t } from '#lib/i18n.svelte.ts';

	/** Snapshots of the database made before upgrades; going back is a command, with the server off. */
	let snapshots = $state<UpgradeSnapshot[]>();

	onMount(async () => {
		snapshots = await api.upgradeSnapshots().catch(() => []);
	});

	async function remove(snap: UpgradeSnapshot) {
		const ask = t('snapshotsCard.deleteThisSnapshotItWill');
		if (!confirm(ask)) return;
		try {
			await api.deleteUpgradeSnapshot(snap.name);
			snapshots = snapshots?.filter((entry) => entry.name !== snap.name);
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('snapshotsCard.notDeleted'));
		}
	}
</script>

<Card id="snapshots" title={t('snapshotsCard.snapshotsBeforeUpgrades')}>
	<p class="alb-meta">
		{t('snapshotsCard.beforeEachUpgradeThatChanges')}
	</p>
	{#if snapshots === undefined}
		<Skeleton height="56px" />
	{:else if snapshots.length === 0}
		<p class="alb-meta">
			{t('snapshotsCard.noSnapshotsYetTheFirst')}
		</p>
	{:else}
		<ul class="set-list" aria-label={t('snapshotsCard.snapshotsBeforeUpgrades')}>
			{#each snapshots as snap (snap.name)}
				<li data-snapshot={snap.name}>
					<span class="set-list-t">
						<b>{snap.fromVersion || t('snapshotsCard.earlierVersion')} → {snap.toVersion}</b>
						<small>
							<time datetime={snap.createdAt}
								>{new Date(snap.createdAt).toLocaleString(dateLocale())}</time
							>
							· {formatBytes(snap.sizeBytes)} · <span class="mono">{snap.name}</span>
						</small>
					</span>
					<Button small variant="danger" onclick={() => remove(snap)}>{t('common.delete')}</Button>
				</li>
			{/each}
		</ul>
		<p class="alb-meta">
			{t('snapshotsCard.toGoBackToThe')}
		</p>
		<pre class="snap-cmd"><code
				>docker compose stop server worker
docker compose run --rm server rollback</code
			></pre>
	{/if}
</Card>
