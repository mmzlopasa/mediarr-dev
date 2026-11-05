<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { adminNav } from '#lib/nav.ts';

	let { children, data }: LayoutProps = $props();
</script>

<AppShell
	nav={adminNav}
	user={data.user}
	tag="ADMIN"
	roleLabel={tr('Administrator', 'Administrator')}
	footLinks={[
		{ href: resolve('/(app)/account'), icon: 'user', label: tr('Račun', 'Account') },
		{ href: resolve('/(app)'), icon: 'photo', label: tr('Mediji', 'Media') }
	]}
>
	{@render children()}
</AppShell>
