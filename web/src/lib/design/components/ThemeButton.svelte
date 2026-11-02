<script lang="ts">
	import { tr } from '#lib/i18n.svelte.ts';
	import { toggleTheme } from '../theme';
	import Icon from './Icon.svelte';
</script>

<button
	type="button"
	class="icon-btn"
	data-theme-btn
	aria-label={tr('Promijeni temu', 'Toggle theme')}
	title={tr('Svijetla / tamna tema', 'Light / dark theme')}
	onclick={toggleTheme}
>
	<span class="i-sun"><Icon name="sun" /></span>
	<span class="i-moon"><Icon name="moon" /></span>
</button>
