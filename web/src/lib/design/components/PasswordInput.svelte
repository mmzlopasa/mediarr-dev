<script lang="ts">
	import { t } from '#lib/i18n.svelte.ts';
	import Icon from './Icon.svelte';

	let { label, name = 'password' }: { label: string; name?: string } = $props();
	let visible = $state(false);
</script>

<label class="f">
	<span>{label}</span>
	<span class="pw">
		<input class="in" type={visible ? 'text' : 'password'} {name} autocomplete="current-password" />
		<button
			type="button"
			class="pw-t"
			aria-label={t('passwordInput.showPassword')}
			aria-pressed={visible}
			onclick={() => (visible = !visible)}><Icon name="eye" /></button
		>
	</span>
</label>
