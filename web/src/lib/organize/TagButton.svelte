<script lang="ts">
	import { api, type Tag } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { t } from '#lib/i18n.svelte.ts';

	let { ids, onDone }: { ids: string[]; onDone: () => void } = $props();

	let open = $state(false);
	let tags = $state<Tag[]>([]);
	let name = $state('');
	let busy = $state(false);

	async function show() {
		open = true;
		tags = await api.tags().catch(() => []);
	}

	async function add(value: string) {
		busy = true;
		try {
			const { changed } = await api.changeTag(ids, value);
			showToast('ok', t('tagButton.taggedChanged', { changed }));
			name = '';
			open = false;
			onDone();
		} catch {
			showToast('err', t('common.theActionFailed'));
		} finally {
			busy = false;
		}
	}

	function submit(event: SubmitEvent) {
		event.preventDefault();
		add(name);
	}
</script>

<button
	type="button"
	class="icon-btn"
	aria-label={t('tagButton.addATag')}
	title={t('tagButton.addATag')}
	onclick={show}><Icon name="list" /></button
>

<Dialog title={t('tagButton.addATag')} bind:open>
	{#each tags as tag (tag.id)}
		<div class="alb-list">
			<b>{tag.name}</b>
			<Button small disabled={busy} onclick={() => add(tag.name)}>{t('common.add')}</Button>
		</div>
	{/each}
	<form class="form" onsubmit={submit}>
		<Input label={t('tagButton.newTag')} maxlength={100} bind:value={name} />
		<Button type="submit" small variant="gold" disabled={busy || !name.trim()}
			>{t('tagButton.createAndAdd')}</Button
		>
	</form>
</Dialog>
