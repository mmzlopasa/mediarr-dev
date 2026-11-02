<script lang="ts">
	let {
		tabs,
		active = $bindable(),
		label
	}: { tabs: { id: string; label: string }[]; active: string; label: string } = $props();
</script>

<div class="tabs sm" role="tablist" aria-label={label}>
	{#each tabs as tab (tab.id)}
		<a
			class="tab"
			class:on={tab.id === active}
			role="tab"
			aria-selected={tab.id === active}
			href="#{tab.id}"
			onclick={(event) => {
				event.preventDefault();
				active = tab.id;
			}}>{tab.label}</a
		>
	{/each}
</div>
