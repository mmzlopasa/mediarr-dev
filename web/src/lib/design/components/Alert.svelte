<script lang="ts">
	import type { Snippet } from 'svelte';
	import Icon from './Icon.svelte';

	let { kind, children }: { kind: 'ok' | 'warn' | 'err'; children: Snippet } = $props();
</script>

<div class="alert {kind}" role={kind === 'err' ? 'alert' : 'status'}>
	<Icon name={kind === 'ok' ? 'check' : 'warn'} /><span>{@render children()}</span>
</div>
