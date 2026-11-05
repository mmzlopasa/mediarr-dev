<script lang="ts">
	// Mono is for data from the camera and the file, never for words.
	let { label, value, mono = false }: { label: string; value: string; mono?: boolean } = $props();
</script>

<div class="kv"><span>{label}</span><b class:kv-mono={mono}>{value}</b></div>
