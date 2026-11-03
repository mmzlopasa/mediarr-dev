<script lang="ts">
	import { api, type Album, type ShareLink } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Checkbox from '#lib/design/components/Checkbox.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { lang, tr } from '#lib/i18n.svelte.ts';

	let { album, open = $bindable(false) }: { album: Album; open?: boolean } = $props();

	let links = $state<ShareLink[]>();
	let failed = $state(false);
	let created = $state<string>();
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
			label = password = expires = limit = watermark = '';
			await load();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error
					? cause.message
					: tr('Link nije stvoren.', 'The link was not created.')
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
			showToast('err', tr('Radnja nije uspjela.', 'The action failed.'));
		}
	}

	async function copy(event: MouseEvent) {
		const input = (event.currentTarget as HTMLElement).parentElement?.querySelector('input');
		input?.select();
		// On plain HTTP the browser has no clipboard API, and the selected text can be copied by hand.
		if (navigator.clipboard && created) {
			await navigator.clipboard.writeText(created);
			showToast('ok', tr('Kopirano.', 'Copied.'));
		}
	}

	function summary(link: ShareLink) {
		const parts = [
			link.uploadOnly ? tr('samo upload', 'upload only') : '',
			link.hasPassword ? tr('lozinka', 'password') : '',
			link.watermark ? tr('watermark', 'watermark') : '',
			link.expiresAt
				? tr('istječe ', 'expires ') + new Date(link.expiresAt).toLocaleDateString(locale)
				: '',
			link.uploadOnly
				? ''
				: tr('preuzimanja: ', 'downloads: ') +
					link.downloadCount +
					(link.downloadLimit ? ` / ${link.downloadLimit}` : '')
		];
		return parts.filter(Boolean).join(' · ');
	}
</script>

<Dialog title={tr('Javni linkovi', 'Public links')} bind:open>
	{#if created}
		<Alert kind="ok">
			{tr(
				'Kopirajte adresu sada: kasnije se više ne može prikazati.',
				'Copy the address now: it cannot be shown again later.'
			)}
		</Alert>
		<div class="form">
			<input class="in" readonly value={created} aria-label={tr('Adresa linka', 'Link address')} />
			<Button small variant="gold" onclick={copy}>{tr('Kopiraj', 'Copy')}</Button>
		</div>
	{/if}
	{#if failed}
		<Alert kind="err">{tr('Linkovi se nisu učitali.', 'Links could not be loaded.')}</Alert>
	{:else if !links}
		<Skeleton height="60px" />
	{:else}
		{#each links as link (link.id)}
			<div class="alb-list">
				<b>
					{link.label || tr('Link bez naziva', 'Unnamed link')}
					<span class="alb-meta">{summary(link)}</span>
				</b>
				<Button small variant="danger" onclick={() => revoke(link.id)}
					>{tr('Opozovi', 'Revoke')}</Button
				>
			</div>
		{/each}
	{/if}
	<form class="form" onsubmit={create}>
		<Input label={tr('Naziv', 'Name')} bind:value={label} />
		<Input
			label={tr('Lozinka (nije obavezna)', 'Password (optional)')}
			type="password"
			autocomplete="new-password"
			bind:value={password}
		/>
		<Input label={tr('Istječe', 'Expires')} type="date" bind:value={expires} />
		{#if !uploadOnly}
			<Input
				label={tr('Limit preuzimanja', 'Download limit')}
				type="number"
				min="1"
				bind:value={limit}
			/>
			<Input
				label={tr('Watermark', 'Watermark')}
				hint={tr(
					'Isključuje preuzimanje originala i reprodukciju videa.',
					'Turns off original downloads and video playback.'
				)}
				maxlength={100}
				bind:value={watermark}
			/>
			<Checkbox label={tr('Dopusti preuzimanje', 'Allow downloads')} bind:checked={allowDownload} />
			<Checkbox label={tr('Prikaži lokaciju', 'Show location')} bind:checked={showLocation} />
		{/if}
		{#if !album.isSmart}
			<Checkbox
				label={tr('Gosti mogu dodavati', 'Guests can add photos')}
				bind:checked={allowUpload}
			/>
			<Checkbox
				label={tr('Samo upload (gosti ne vide album)', 'Upload only (guests do not see the album)')}
				bind:checked={uploadOnly}
			/>
		{/if}
		<Button type="submit" small variant="gold" disabled={busy}
			>{tr('Stvori link', 'Create link')}</Button
		>
	</form>
</Dialog>
