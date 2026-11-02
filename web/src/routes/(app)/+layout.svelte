<script lang="ts">
	import { resolve } from '$app/paths';
	import type { LayoutProps } from './$types';
	import AppShell from '#lib/design/components/AppShell.svelte';
	import Dropzone from '#lib/design/components/Dropzone.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
	import { appNav } from '#lib/nav.ts';

	let { children, data }: LayoutProps = $props();
</script>

<AppShell
	nav={appNav}
	user={data.user}
	roleLabel={tr('Korisnik', 'User')}
	footLabel={tr('Fotografije', 'Photos')}
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
	{@render children()}
</AppShell>
<Dropzone />
