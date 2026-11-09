<script lang="ts">
	import { api, type Album, type ShareLink, type Features } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Checkbox from '#lib/design/components/Checkbox.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, t } from '#lib/i18n.svelte.ts';

	let { album, open = $bindable(false) }: { album: Album; open?: boolean } = $props();

	let links = $state<ShareLink[]>();
	let failed = $state(false);
	let created = $state<string>();
	let createdKiosk = $state<string>();
	let kioskOn = $state(false);
	let busy = $state(false);

	let label = $state('');
	let password = $state('');
	let expires = $state('');
	let limit = $state('');
	let watermark = $state('');
	let allowDownload = $state(true);
	let allowUpload = $state(false);
	let uploadOnly = $state(false);
	let showLocation = $state(false);

	const locale = $derived(lang() === 'hr' ? 'hr-HR' : 'en-GB');

	async function load() {
		try {
			links = await api.links(album.id);
			failed = false;
		} catch {
			failed = true;
		}
	}

	$effect(() => {
		if (open) {
			created = undefined;
			load();
		}
	});

	async function create(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		try {
			const link = await api.createLink(album.id, {
				label,
				password: password || undefined,
				expiresAt: expires ? new Date(`${expires}T23:59:59`).toISOString() : undefined,
				downloadLimit: limit ? Number(limit) : undefined,
				watermark: watermark || undefined,
				allowDownload,
				allowUpload,
				uploadOnly,
				showLocation
			});
			// Built from the address in use, so this works on an IP address as well as on a domain.
			created = `${location.origin}/s/${link.token}`;
			createdKiosk = `${location.origin}/kiosk/${link.token}`;
			kioskOn = (await api.features().catch(() => ({ kiosk: false }) as Features)).kiosk ?? false;
			label = password = expires = limit = watermark = '';
			await load();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : t('linksDialog.theLinkWasNotCreated')
			);
		} finally {
			busy = false;
		}
	}

	async function revoke(id: string) {
		try {
			await api.deleteLink(album.id, id);
			await load();
		} catch {
			showToast('err', t('common.theActionFailed'));
		}
	}

	async function copy(event: MouseEvent) {
		const input = (event.currentTarget as HTMLElement).parentElement?.querySelector('input');
		input?.select();
		// On plain HTTP the browser has no clipboard API, and the selected text can be copied by hand.
		if (navigator.clipboard && created) {
			await navigator.clipboard.writeText(created);
			showToast('ok', t('linksDialog.copied'));
		}
	}

	function summary(link: ShareLink) {
		const parts = [
			link.uploadOnly ? t('linksDialog.uploadOnly') : '',
			link.hasPassword ? t('linksDialog.password') : '',
			link.watermark ? t('linksDialog.watermark') : '',
			link.expiresAt
				? t('linksDialog.expires') + new Date(link.expiresAt).toLocaleDateString(locale)
				: '',
			link.uploadOnly
				? ''
				: t('linksDialog.downloads') +
					link.downloadCount +
					(link.downloadLimit ? ` / ${link.downloadLimit}` : '')
		];
		return parts.filter(Boolean).join(' · ');
	}
</script>

<Dialog title={t('linksDialog.publicLinks')} bind:open>
	{#if created}
		<Alert kind="ok">
			{t('linksDialog.copyTheAddressNowIt')}
		</Alert>
		<div class="form">
			<input class="in" readonly value={created} aria-label={t('linksDialog.linkAddress')} />
			<Button small variant="gold" onclick={copy}>{t('linksDialog.copy')}</Button>
		</div>
		{#if kioskOn}
			<p class="alb-meta">
				{t('linksDialog.aSlideshowForATv')}
			</p>
			<input
				class="in"
				readonly
				value={createdKiosk}
				aria-label={t('linksDialog.slideshowAddress')}
			/>
		{/if}
	{/if}
	{#if failed}
		<Alert kind="err">{t('linksDialog.linksCouldNotBeLoaded')}</Alert>
	{:else if !links}
		<Skeleton height="60px" />
	{:else}
		{#each links as link (link.id)}
			<div class="alb-list">
				<b>
					{link.label || t('linksDialog.unnamedLink')}
					<span class="alb-meta">{summary(link)}</span>
				</b>
				<Button small variant="danger" onclick={() => revoke(link.id)}
					>{t('linksDialog.revoke')}</Button
				>
			</div>
		{/each}
	{/if}
	<form class="form" onsubmit={create}>
		<Input label={t('common.name')} bind:value={label} />
		<Input
			label={t('linksDialog.passwordOptional')}
			type="password"
			autocomplete="new-password"
			bind:value={password}
		/>
		<Input label={t('linksDialog.expires2')} type="date" bind:value={expires} />
		{#if !uploadOnly}
			<Input label={t('linksDialog.downloadLimit')} type="number" min="1" bind:value={limit} />
			<Input
				label={t('linksDialog.watermark2')}
				hint={t('linksDialog.turnsOffOriginalDownloadsAnd')}
				maxlength={100}
				bind:value={watermark}
			/>
			<Checkbox label={t('linksDialog.allowDownloads')} bind:checked={allowDownload} />
			<Checkbox label={t('linksDialog.showLocation')} bind:checked={showLocation} />
		{/if}
		{#if !album.isSmart}
			<Checkbox label={t('linksDialog.guestsCanAddPhotos')} bind:checked={allowUpload} />
			<Checkbox label={t('linksDialog.uploadOnlyGuestsDoNot')} bind:checked={uploadOnly} />
		{/if}
		<Button type="submit" small variant="gold" disabled={busy}>{t('linksDialog.createLink')}</Button
		>
	</form>
</Dialog>
