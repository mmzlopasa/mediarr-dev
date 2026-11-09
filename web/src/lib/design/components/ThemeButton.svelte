<script lang="ts">
	import { t } from '#lib/i18n.svelte.ts';
	import { toggleTheme } from '../theme';
	import Icon from './Icon.svelte';
</script>

<button
	type="button"
	class="icon-btn"
	data-theme-btn
	aria-label={t('themeButton.toggleTheme')}
	title={t('themeButton.lightDarkTheme')}
	onclick={toggleTheme}
>
	<span class="i-sun"><Icon name="sun" /></span>
	<span class="i-moon"><Icon name="moon" /></span>
</button>
