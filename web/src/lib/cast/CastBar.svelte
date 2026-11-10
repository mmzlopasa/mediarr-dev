<script lang="ts">
	import Icon from '#lib/design/components/Icon.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import { formatDuration } from '#lib/timeline/layout.ts';
	import { casting, playOrPause, seekTo, stopCasting } from './session.svelte.ts';

	/** While a TV shows what is on the screen: its name, and for a video, play, pause and seeking. */
	const now = $derived(casting());
</script>

{#if now}
	<div class="tv-bar" role="region" aria-label={t('cast.playingOn', { device: now.device })}>
		<Icon name="tv" size={16} />
		<span class="tv-bar-name">{t('cast.playingOn', { device: now.device })}</span>
		{#if now.kind === 'video' && now.target === 'chromecast'}
			<button
				type="button"
				class="icon-btn"
				aria-label={now.paused ? t('cast.play') : t('cast.pause')}
				onclick={playOrPause}
			>
				{#if now.paused}<Icon name="play" />{:else}<svg
						viewBox="0 0 24 24"
						width="18"
						height="18"
						aria-hidden="true"
						><path d="M7 5h3.5v14H7zM13.5 5H17v14h-3.5z" fill="currentColor" /></svg
					>{/if}
			</button>
			<input
				class="tv-bar-seek"
				type="range"
				min="0"
				max={Math.max(now.duration, 1)}
				step="1"
				value={now.position}
				aria-label={t('cast.position')}
				onchange={(event) => seekTo(Number(event.currentTarget.value))}
			/>
			<span class="tv-bar-time">{formatDuration(now.position * 1000)}</span>
		{/if}
		<button type="button" class="btn sm" onclick={() => stopCasting()}>{t('cast.stop')}</button>
	</div>
{/if}
