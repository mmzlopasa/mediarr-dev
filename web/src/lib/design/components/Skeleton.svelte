<script lang="ts">
	let { width = '100%', height = '16px' }: { width?: string; height?: string } = $props();
</script>

<span class="skel" style="width:{width};height:{height}" aria-hidden="true"></span>
