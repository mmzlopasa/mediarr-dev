<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import Dropzone from '#lib/design/components/Dropzone.svelte';
	import ServerStatus from '#lib/design/components/ServerStatus.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';
	import { loadPreferences, preferences } from '#lib/preferences.svelte.ts';
	import { onMount } from 'svelte';

	let { children, data }: LayoutProps = $props();

	onMount(loadPreferences);

	const shownNav = $derived(
		appNav.filter((item) => !preferences()?.hiddenSections.includes(item.path))
	);
</script>

<AppShell
	nav={shownNav}
	user={data.user}
	roleLabel={tr('Korisnik', 'User')}
	footLinks={[
		{ href: resolve('/(app)/account'), icon: 'user', label: tr('Račun', 'Account') },
		{
			href: resolve('/(app)/account/devices'),
			icon: 'phone',
			label: tr('Uređaji za backup', 'Backup devices')
		},
		{ href: resolve('/(app)/account/import'), icon: 'download', label: tr('Uvoz', 'Import') },
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
