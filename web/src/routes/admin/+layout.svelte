<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import { t } from '#lib/i18n.svelte.ts';
	import { adminNav } from '#lib/nav.ts';

	let { children, data }: LayoutProps = $props();
</script>

<AppShell
	nav={adminNav}
	user={data.user}
	tag="ADMIN"
	roleLabel={t('admin.administrator')}
	footLinks={[
		{ href: resolve('/(app)/account'), icon: 'user', label: t('common.account') },
		{ href: resolve('/(app)'), icon: 'photo', label: t('admin.media') }
	]}
>
	{@render children()}
</AppShell>
