<script lang="ts">
	import { onMount } from 'svelte';
	import { pushState, replaceState } from '$app/navigation';
	import { page } from '$app/state';
	import { ApiError, api, publicSource, type PublicLink } from '#lib/api.ts';
	import Alert from '#lib/design/components/Alert.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import LangMenu from '#lib/design/components/LangMenu.svelte';
	import Logo from '#lib/design/components/Logo.svelte';
	import PasswordInput from '#lib/design/components/PasswordInput.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import Timeline from '#lib/timeline/Timeline.svelte';
	import Viewer from '#lib/timeline/Viewer.svelte';

	const POLL_MS = 10000;

	const token = $derived(page.params.token ?? '');
	const base = $derived(`/api/public/${token}`);
	const source = $derived(publicSource(token));

	let link = $state<PublicLink>();
	let gone = $state(false);
	let unlockError = $state('');
	let busy = $state(false);
	let timeline = $state<Timeline>();
	let total = $state<number>();

	let sent = $state(0);
	let failedFiles = $state<string[]>([]);
	let sending = $state(0);

	async function load() {
		try {
			link = await api.publicLink(token);
			gone = false;
			if (!link.locked && !link.uploadOnly) await timeline?.refresh();
		} catch (cause) {
			if (cause instanceof ApiError && cause.status === 404) gone = true;
		}
	}

	onMount(() => {
		const photo = page.url.searchParams.get('photo');
		if (photo) pushState('', { viewer: photo });
	});

	$effect(() => {
		void token;
		load();
		const timer = setInterval(load, POLL_MS);
		return () => clearInterval(timer);
	});

	async function unlock(event: SubmitEvent) {
		event.preventDefault();
		const form = event.currentTarget as HTMLFormElement;
		busy = true;
		unlockError = '';
		try {
			await api.unlockLink(token, String(new FormData(form).get('password') ?? ''));
			await load();
		} catch (cause) {
			unlockError =
				cause instanceof ApiError && cause.status === 429
					? tr('Previše pokušaja. Pokušajte kasnije.', 'Too many attempts. Try again later.')
					: tr('Pogrešna lozinka.', 'Wrong password.');
		} finally {
			busy = false;
		}
	}

	function encoded(value: string) {
		const bytes = new TextEncoder().encode(value);
		return btoa(String.fromCharCode(...bytes));
	}

	// One whole file per request, one at a time: a guest's phone may have a weak connection.
	async function send(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		const files = [...(input.files ?? [])];
		sending += files.length;
		for (const file of files) {
			try {
				const response = await fetch(`${base}/uploads`, {
					method: 'POST',
					headers: {
						'Tus-Resumable': '1.0.0',
						'Upload-Length': String(file.size),
						'Upload-Metadata': `filename ${encoded(file.name)},lastModified ${encoded(String(file.lastModified))}`,
						'Content-Type': 'application/offset+octet-stream'
					},
					body: file
				});
				if (!response.ok) throw new Error(String(response.status));
				sent += 1;
			} catch {
				failedFiles = [...failedFiles, file.name];
			} finally {
				sending -= 1;
			}
		}
		await timeline?.refresh();
	}
</script>

<svelte:head>
	<title>{link?.title ?? 'Mediarr'}</title>
	<meta name="robots" content="noindex" />
	<meta name="referrer" content="no-referrer" />
</svelte:head>

<div class="pub">
	<header class="pub-top">
		<Logo />
		<LangMenu />
	</header>

	{#if gone}
		<div class="pub-box">
			<Alert kind="err">{tr('Ovaj link nije dostupan.', 'This link is not available.')}</Alert>
		</div>
	{:else if !link}
		<Skeleton height="220px" />
	{:else if link.locked}
		<div class="pub-box">
			<Card title={tr('Potrebna je lozinka', 'A password is needed')}>
				<form class="form" onsubmit={unlock}>
					{#if unlockError}<Alert kind="err">{unlockError}</Alert>{/if}
					<PasswordInput label={tr('Lozinka', 'Password')} />
					<Button type="submit" variant="gold" disabled={busy}>{tr('Otvori', 'Open')}</Button>
				</form>
			</Card>
		</div>
	{:else}
		<div class="ph">
			<div>
				<h1>{link.title}</h1>
				{#if link.description}<p>{link.description}</p>{/if}
			</div>
			{#if link.allowUpload}
				<div class="ph-a">
					<label class="btn gold sm">
						{tr('Dodaj fotke', 'Add photos')}
						<input class="sr" type="file" multiple accept="image/*,video/*" onchange={send} />
					</label>
				</div>
			{/if}
		</div>

		{#if sending > 0}<Alert kind="ok">{tr(`Šalje se: ${sending}`, `Sending: ${sending}`)}</Alert
			>{/if}
		{#if sent > 0}<Alert kind="ok"
				>{tr(`Poslano: ${sent}. Hvala!`, `Sent: ${sent}. Thank you!`)}</Alert
			>{/if}
		{#if failedFiles.length > 0}
			<Alert kind="err">{tr('Nisu poslane: ', 'Not sent: ')}{failedFiles.join(', ')}</Alert>
		{/if}

		{#if link.uploadOnly}
			<p class="alb-meta">
				{tr(
					'Fotke idu izravno vlasniku albuma. Sadržaj albuma ovdje se ne prikazuje.',
					'Photos go straight to the album owner. The album itself is not shown here.'
				)}
			</p>
		{:else}
			{#if total === 0}<p class="alb-meta">{tr('Album je prazan.', 'This album is empty.')}</p>{/if}
			<Timeline
				bind:this={timeline}
				{source}
				{base}
				selectable={false}
				ownActions={false}
				downloads={false}
				hrefFor={(photo) => `/s/${token}?photo=${photo}`}
				onOpen={(photo) => pushState('', { viewer: photo })}
				onCount={(count) => (total = count)}
			/>
			{#if page.state.viewer}
				<Viewer
					id={page.state.viewer}
					{base}
					previewOnly={link.watermarked}
					onClose={() => history.back()}
					onNavigate={(photo) => replaceState('', { viewer: photo })}
					onChanged={() => {}}
					neighbours={(photo) => timeline?.neighbours(photo) ?? {}}
				/>
			{/if}
		{/if}
	{/if}
</div>
