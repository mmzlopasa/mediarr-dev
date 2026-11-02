<script lang="ts">
	import Icon from './Icon.svelte';
	import { toasts } from './toast.svelte';
</script>

<div class="toasts" aria-live="polite">
	{#each toasts() as toast (toast.id)}
		<div class="toast glass {toast.kind}" role="status">
			<Icon name={toast.kind === 'ok' ? 'check' : 'warn'} /><span>{toast.text}</span>
		</div>
	{/each}
</div>
