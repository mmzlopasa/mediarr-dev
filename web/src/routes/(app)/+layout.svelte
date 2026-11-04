<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import { api } from '#lib/api.ts';
	import Dropzone from '#lib/design/components/Dropzone.svelte';
	import ServerStatus from '#lib/design/components/ServerStatus.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';

	let { children, data }: LayoutProps = $props();

	const navChildren = {
		'/albums': async () =>
			(await api.albums()).map((album) => ({
				href: `/albums/${album.id}`,
				label: album.title
			}))
	};
</script>

<AppShell
	nav={appNav}
	{navChildren}
	user={data.user}
	roleLabel={tr('Korisnik', 'User')}
	footLabel={tr('Mediji', 'Media')}
	footLinks={[
		{ href: resolve('/(app)/account'), icon: 'user', label: tr('Račun', 'Account') },
		...(data.user.isAdmin
			? [
					{
						href: resolve('/admin'),
						icon: 'shield' as const,
						label: tr('Administracija', 'Administration')
					}
				]
			: [])
	]}
>
	{#snippet sideExtra()}
		<div class="srv-wrap"><ServerStatus /></div>
	{/snippet}
	{@render children()}
</AppShell>
<Dropzone />
