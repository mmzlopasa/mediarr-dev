<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import Dropzone from '#lib/design/components/Dropzone.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';

	let { children }: LayoutProps = $props();
</script>

<AppShell
	nav={appNav}
	roleLabel={tr('Korisnik', 'User')}
	footLabel={tr('Fotografije', 'Photos')}
	footLink={{
		href: resolve('/admin'),
		icon: 'shield',
		label: tr('Administracija', 'Administration')
	}}
>
	{@render children()}
</AppShell>
<Dropzone />
