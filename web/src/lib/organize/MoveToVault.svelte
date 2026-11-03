<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { api, ApiError } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let { ids, onDone }: { ids: string[]; onDone: () => void } = $props();

	async function move() {
		try {
			const { changed } = await api.bulk(ids, 'vault');
			showToast('ok', tr(`Premješteno u trezor: ${changed}`, `Moved to the vault: ${changed}`));
			onDone();
		} catch (cause) {
			if (cause instanceof ApiError && cause.status === 400) {
				showToast('warn', tr('Najprije postavite PIN trezora.', 'Set a vault PIN first.'));
				await goto(resolve('/(app)/vault'));
				return;
			}
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}
</script>

<button
	type="button"
	class="icon-btn"
	aria-label={tr('Premjesti u trezor', 'Move to the vault')}
	title={tr('Premjesti u trezor', 'Move to the vault')}
	onclick={move}><Icon name="lock" /></button
>
