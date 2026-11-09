<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import Dropzone from '#lib/design/components/Dropzone.svelte';
	import ServerStatus from '#lib/design/components/ServerStatus.svelte';
	import { t } from '#lib/i18n.svelte.ts';
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
	roleLabel={t('common.user')}
	footLinks={[
		{ href: resolve('/(app)/account'), icon: 'user', label: t('common.account') },
		{
			href: resolve('/(app)/account/devices'),
			icon: 'phone',
			label: t('common.backupDevices')
		},
		{ href: resolve('/(app)/account/import'), icon: 'download', label: t('common.import') },
		{ href: resolve('/(app)/account/export'), icon: 'upload', label: t('export.title') },
		...(data.user.isAdmin
			? [
					{
						href: resolve('/admin'),
						icon: 'shield' as const,
						label: t('home.administration')
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
