<script lang="ts">
	import { lang, languages, setLang, type Lang } from '#lib/i18n.svelte.ts';

	let menu = $state<HTMLDetailsElement>();

	function pick(event: MouseEvent, code: Lang) {
		event.preventDefault();
		// The menu is on pages without an account, such as signing in.
		setLang(code);
		if (menu) menu.open = false;
	}
</script>

<details class="langdd" bind:this={menu}>
	<summary aria-label="{lang().toUpperCase()} language"
		>{lang().toUpperCase()}<i aria-hidden="true"></i></summary
	>
	<div class="langdd-m" role="menu">
		{#each Object.entries(languages) as [code, name] (code)}
			<a
				role="menuitem"
				href="#{code}"
				hreflang={code}
				lang={code}
				class:on={code === lang()}
				aria-current={code === lang() ? 'true' : undefined}
				onclick={(event) => pick(event, code as Lang)}
				><b>{code.toUpperCase()}</b><span
					>{name.split(' (')[0]}{#if name.includes(' (')}<small
							>{name.slice(name.indexOf(' (') + 2, -1)}</small
						>{/if}</span
				></a
			>
		{/each}
	</div>
</details>
