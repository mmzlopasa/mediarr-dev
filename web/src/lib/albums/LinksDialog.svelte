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
	import { since } from '#lib/organize/agent.ts';
	import LinkPrivacyFields from './LinkPrivacyFields.svelte';
	import LinkVisits from './LinkVisits.svelte';
	import { newPrivacy, privacyBody, privacyOf, type PrivacyOptions } from './linkPrivacy.ts';

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
	let privacy = $state<PrivacyOptions>(newPrivacy());

	// One link at a time has its options open, or its visits.
	let editing = $state<{ id: string; options: PrivacyOptions }>();
	let saving = $state(false);
	let visitsOf = $state<string>();

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
			editing = undefined;
			visitsOf = undefined;
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
				...privacyBody(privacy)
			});
			// Built from the address in use, so this works on an IP address as well as on a domain.
			created = `${location.origin}/s/${link.token}`;
			createdKiosk = `${location.origin}/kiosk/${link.token}`;
			kioskOn = (await api.features().catch(() => ({ kiosk: false }) as Features)).kiosk ?? false;
			label = password = expires = limit = watermark = '';
			privacy = newPrivacy();
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

	function edit(link: ShareLink) {
		visitsOf = undefined;
		editing = editing?.id === link.id ? undefined : { id: link.id, options: privacyOf(link) };
	}

	function showVisits(link: ShareLink) {
		editing = undefined;
		visitsOf = visitsOf === link.id ? undefined : link.id;
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		if (!editing) return;
		saving = true;
		try {
			const changed = await api.updateLink(album.id, editing.id, privacyBody(editing.options));
			links = links?.map((link) => (link.id === changed.id ? changed : link));
			editing = undefined;
			showToast('ok', t('linkPrivacy.saved'));
		} catch (cause) {
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
		} finally {
			saving = false;
		}
	}

	function opened(link: ShareLink) {
		if (link.visits === undefined) return '';
		if (link.visits === 0) return t('linkPrivacy.notOpenedYet');
		const times = t('linkPrivacy.openedTimes', { count: link.visits });
		return link.lastVisitAt
			? `${times} · ${t('linkPrivacy.lastWhen', { when: since(new Date(link.lastVisitAt)) })}`
			: times;
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
			link.hideFaces && link.hideFaces !== 'none' ? t('linkPrivacy.facesHidden') : '',
			link.askName ? t('linkPrivacy.asksForAName') : '',
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
		<div class="lp-preview">
			<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -- the full address of the new link, in a new tab -->
			<a class="btn sm" href={created} target="_blank" rel="noopener"
				>{t('linkPrivacy.previewAsAVisitor')}</a
			>
			<small class="hint">{t('linkPrivacy.yourOwnVisitsAreNot')}</small>
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
					{#if opened(link)}<span class="alb-meta">{opened(link)}</span>{/if}
				</b>
				{#if !link.uploadOnly}
					<Button small aria-expanded={editing?.id === link.id} onclick={() => edit(link)}
						>{t('linkPrivacy.privacy')}</Button
					>
				{/if}
				<Button small aria-expanded={visitsOf === link.id} onclick={() => showVisits(link)}
					>{t('linkPrivacy.whoOpenedIt')}</Button
				>
				<Button small variant="danger" onclick={() => revoke(link.id)}
					>{t('linksDialog.revoke')}</Button
				>
			</div>
			{#if editing?.id === link.id}
				<form class="form lp-edit" onsubmit={save} aria-label={t('linkPrivacy.privacy')}>
					<LinkPrivacyFields albumId={album.id} bind:options={editing.options} />
					<div class="lp-actions">
						<Button type="submit" small variant="gold" disabled={saving}>{t('common.save')}</Button>
						<Button small onclick={() => (editing = undefined)}>{t('common.cancel')}</Button>
					</div>
				</form>
			{/if}
			{#if visitsOf === link.id}
				<LinkVisits albumId={album.id} linkId={link.id} />
			{/if}
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
			<LinkPrivacyFields albumId={album.id} bind:options={privacy} />
		{/if}
		{#if !album.isSmart}
			<Checkbox label={t('linksDialog.guestsCanAddPhotos')} bind:checked={allowUpload} />
			<Checkbox label={t('linksDialog.uploadOnlyGuestsDoNot')} bind:checked={uploadOnly} />
		{/if}
		<Button type="submit" small variant="gold" disabled={busy}>{t('linksDialog.createLink')}</Button
		>
	</form>
</Dialog>
