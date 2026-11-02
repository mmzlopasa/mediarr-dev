<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { adminNav } from '#lib/nav.ts';

	let { children }: LayoutProps = $props();
</script>

<AppShell
	nav={adminNav}
	tag="ADMIN"
	roleLabel={tr('Administrator', 'Administrator')}
	footLabel={tr('Administracija', 'Administration')}
	footLink={{ href: resolve('/(app)'), icon: 'photo', label: tr('Fotografije', 'Photos') }}
>
	{@render children()}
</AppShell>
