<script lang="ts">
	let { label, checked = $bindable(false) }: { label: string; checked?: boolean } = $props();
</script>

<label class="chk"><input type="checkbox" bind:checked /> {label}</label>
