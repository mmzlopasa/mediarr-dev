<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { api, ApiError, publicSource, type PublicLink } from '#lib/api.ts';
	import { t } from '#lib/i18n.svelte.ts';

	const SHOW_MS = 10000;
	const REFRESH_MS = 10 * 60000;
	// After a failure the frame asks again soon, so it recovers by itself once the server is back.
	const RETRY_MS = 30000;

	const token = $derived(page.params.token ?? '');
	const base = $derived(`/api/public/${token}`);

	let link = $state<PublicLink>();
	let photos = $state<string[]>([]);
	let index = $state(0);
	let gone = $state(false);
	let failed = $state(false);
	let retry: ReturnType<typeof setTimeout> | undefined;

	async function load() {
		clearTimeout(retry);
		try {
			link = await api.publicLink(token);
			gone = false;
			failed = false;
			// A link that asks each visitor for a name has nobody to ask here.
			if (!link.kiosk || link.locked || link.uploadOnly || (link.askName && !link.named)) return;
			const source = publicSource(token);
			const { buckets } = await source.buckets();
			const found: string[] = [];
			for (const bucket of buckets) {
				const { items } = await source.bucket(bucket.month);
				found.push(...items.filter((item) => item.kind === 'photo').map((item) => item.id));
			}
			photos = found;
		} catch (cause) {
			// A revoked link stops the frame, which then says so.
			if (cause instanceof ApiError && (cause.status === 404 || cause.status === 410)) gone = true;
			else if (photos.length === 0) {
				// Nothing to show yet: say why, and try again; photos already shown keep going.
				failed = true;
				retry = setTimeout(load, RETRY_MS);
			}
		}
	}

	onMount(() => {
		load();
		const refresh = setInterval(load, REFRESH_MS);
		const next = setInterval(() => {
			if (photos.length > 0) index = (index + 1) % photos.length;
		}, SHOW_MS);
		return () => {
			clearTimeout(retry);
			clearInterval(refresh);
			clearInterval(next);
		};
	});

	const message = $derived(
		gone
			? t('kiosk.token.thisLinkNoLongerWorks')
			: failed
				? t('kiosk.token.serverUnreachable')
				: link && link.askName && !link.named
					? t('kiosk.token.asksForAName')
					: link && !link.kiosk
						? t('kiosk.token.anAdministratorHasNotTurned')
						: link?.locked
							? t('kiosk.token.aSlideshowDoesNotWork')
							: link && photos.length === 0
								? t('kiosk.token.thisAlbumIsEmpty')
								: ''
	);
</script>

<svelte:head><title>{link?.title ?? 'Mediarr'}</title></svelte:head>

<div class="kiosk">
	{#if message}
		<p>{message}</p>
	{:else if photos.length > 0}
		{#key photos[index]}
			<img src="{base}/assets/{photos[index]}/thumbnail?size=large" alt="" />
		{/key}
	{/if}
</div>
