<script lang="ts">
	import { pulse } from '#lib/motion/actions.ts';
	import { api, type Activity } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { dateLocale, t } from '#lib/i18n.svelte.ts';

	const POLL_MS = 10000;

	let { albumId, assetId, revision }: { albumId: string; assetId?: string; revision?: string } =
		$props();

	let activity = $state<Activity>();
	let failed = $state(false);
	let text = $state('');
	let busy = $state(false);

	const locale = $derived(dateLocale());

	async function load() {
		try {
			activity = await api.activity(albumId, assetId);
			failed = false;
		} catch {
			failed = true;
		}
	}

	$effect(() => {
		void revision;
		activity = undefined;
		load();
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	async function send(event: SubmitEvent) {
		event.preventDefault();
		const body = text.trim();
		if (!body) return;
		busy = true;
		try {
			await api.addComment(albumId, body, assetId);
			text = '';
			await load();
		} catch {
			showToast('err', t('albumActivity.theCommentWasNotSent'));
		} finally {
			busy = false;
		}
	}

	async function remove(id: string) {
		try {
			await api.deleteComment(albumId, id);
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function heart(event: MouseEvent) {
		if (!assetId || !activity) return;
		pulse((event.currentTarget as HTMLElement).querySelector('svg'));
		try {
			await api.setHeart(albumId, assetId, !activity.hearted);
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

{#if failed && !activity}
	<Alert kind="err">{t('albumActivity.commentsCouldNotBeLoaded')}</Alert>
{:else if !activity}
	<Skeleton height="60px" />
{:else}
	{#if assetId}
		<div class="alb-heart">
			<button
				type="button"
				class="icon-btn"
				class:on={activity.hearted}
				aria-pressed={activity.hearted}
				aria-label={t('albumActivity.heart')}
				onclick={heart}><Icon name="heart" /></button
			>
			<span>{activity.hearts}</span>
		</div>
	{/if}
	{#each activity.comments as comment (comment.id)}
		<div class="alb-comment">
			<div class="alb-comment-h">
				<b>{comment.userName}</b>
				<small>{new Date(comment.createdAt).toLocaleString(locale)}</small>
				{#if comment.canDelete}
					<button
						type="button"
						class="icon-btn sm"
						aria-label={t('albumActivity.deleteComment')}
						onclick={() => remove(comment.id)}>✕</button
					>
				{/if}
			</div>
			<p>{comment.body}</p>
		</div>
	{:else}
		<p class="alb-meta">{t('albumActivity.noCommentsYet')}</p>
	{/each}
	<form class="form" onsubmit={send}>
		<Input label={t('albumActivity.comment')} bind:value={text} maxlength={2000} />
		<Button type="submit" small disabled={busy || !text.trim()}>{t('albumActivity.send')}</Button>
	</form>
{/if}
