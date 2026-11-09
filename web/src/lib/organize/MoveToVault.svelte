<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { api, ApiError } from '#lib/api.ts';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	let { ids, onDone }: { ids: string[]; onDone: () => void } = $props();

	async function move() {
		try {
			const { changed } = await api.bulk(ids, 'vault');
			showToast('ok', t('moveToVault.movedToTheVaultChanged', { changed }));
			onDone();
		} catch (cause) {
			if (cause instanceof ApiError && cause.status === 400) {
				showToast('warn', t('moveToVault.setAVaultPinFirst'));
				await goto(resolve('/(app)/vault'));
				return;
			}
			showToast('err', t('common.theActionFailed'));
		}
	}
</script>

<button
	type="button"
	class="icon-btn"
	aria-label={t('moveToVault.moveToTheVault')}
	title={t('moveToVault.moveToTheVault')}
	onclick={move}><Icon name="lock" /></button
>
