<script lang="ts">
	import { pulse } from '#lib/motion/actions.ts';
	import { api, type Activity } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, tr } from '#lib/i18n.svelte.ts';

	const POLL_MS = 10000;

	let { albumId, assetId, revision }: { albumId: string; assetId?: string; revision?: string } =
		$props();

	let activity = $state<Activity>();
	let failed = $state(false);
	let text = $state('');
	let busy = $state(false);

	const locale = $derived(lang() === 'hr' ? 'hr-HR' : 'en-GB');

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
			showToast('err', tr('Komentar nije poslan.', 'The comment was not sent.'));
		} finally {
			busy = false;
		}
	}

	async function remove(id: string) {
		try {
			await api.deleteComment(albumId, id);
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function heart(event: MouseEvent) {
		if (!assetId || !activity) return;
		pulse((event.currentTarget as HTMLElement).querySelector('svg'));
		try {
			await api.setHeart(albumId, assetId, !activity.hearted);
			await load();
		} catch {
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

{#if failed && !activity}
	<Alert kind="err">{tr('Komentari se nisu učitali.', 'Comments could not be loaded.')}</Alert>
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
				aria-label={tr('Srce', 'Heart')}
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
						aria-label={tr('Obriši komentar', 'Delete comment')}
						onclick={() => remove(comment.id)}>✕</button
					>
				{/if}
			</div>
			<p>{comment.body}</p>
		</div>
	{:else}
		<p class="alb-meta">{tr('Još nema komentara.', 'No comments yet.')}</p>
	{/each}
	<form class="form" onsubmit={send}>
		<Input label={tr('Komentar', 'Comment')} bind:value={text} maxlength={2000} />
		<Button type="submit" small disabled={busy || !text.trim()}>{tr('Pošalji', 'Send')}</Button>
	</form>
{/if}
