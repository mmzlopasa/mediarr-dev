<script lang="ts">
	import { api, type LinkVisit } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { dateLocale, t } from '#lib/i18n.svelte.ts';
	import { placeOf } from './linkPrivacy.ts';

	let { albumId, linkId }: { albumId: string; linkId: string } = $props();

	let visits = $state<LinkVisit[]>();
	let failed = $state(false);

	const locale = $derived(dateLocale());

	$effect(() => {
		visits = undefined;
		failed = false;
		api
			.linkVisits(albumId, linkId)
			.then((list) => (visits = list))
			.catch(() => (failed = true));
	});
</script>

<section class="lp-visits" aria-label={t('linkPrivacy.whoOpenedIt')}>
	{#if failed}
		<Alert kind="err">{t('common.thisCouldNotBeLoaded')}</Alert>
	{:else if !visits}
		<Skeleton height="80px" />
	{:else if visits.length === 0}
		<p class="alb-meta">{t('linkPrivacy.nobodyHasOpenedThisLink')}</p>
	{:else}
		<div class="tbl-w">
			<table class="tbl">
				<thead>
					<tr>
						<th>{t('linkPrivacy.when')}</th>
						<th>{t('linkPrivacy.who')}</th>
						<th>{t('linkPrivacy.place')}</th>
						<th>{t('linkPrivacy.device')}</th>
						<th>{t('linkPrivacy.viewed')}</th>
						<th>{t('linkPrivacy.downloaded')}</th>
					</tr>
				</thead>
				<tbody>
					{#each visits as visit, index (index)}
						<tr>
							<td
								><time datetime={visit.at}
									>{new Date(visit.at).toLocaleString(locale, {
										dateStyle: 'medium',
										timeStyle: 'short'
									})}</time
								></td
							>
							<td>{visit.name || '—'}</td>
							<td>{placeOf(visit) ?? t('linkPrivacy.unknownPlace')}</td>
							<td>{visit.device}</td>
							<td>{visit.viewed}</td>
							<td>{visit.downloaded}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
	<small class="hint">{t('linkPrivacy.placesByDbIp')}</small>
</section>
