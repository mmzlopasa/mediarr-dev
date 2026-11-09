<script lang="ts">
	import { api } from '#lib/api.ts';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	const STARS = [1, 2, 3, 4, 5];

	let {
		assetId,
		rating,
		onChanged
	}: { assetId: string; rating: number; onChanged: () => void | Promise<void> } = $props();

	// Choosing the stars it already has takes them away.
	async function rate(stars: number) {
		try {
			await api.setAssetFacts(assetId, { rating: stars === rating ? 0 : stars });
			await onChanged();
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.notSaved'));
		}
	}
</script>

<div class="stars" role="group" aria-label={t('ratingStars.rating')}>
	{#each STARS as stars (stars)}
		<button
			type="button"
			class="star"
			class:on={stars <= rating}
			aria-pressed={stars === rating}
			aria-label={t('ratingStars.starsOf5Stars', { stars })}
			onclick={() => rate(stars)}>★</button
		>
	{/each}
</div>
