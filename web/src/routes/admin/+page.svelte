<script lang="ts">
	import Card from '#lib/design/components/Card.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Stat from '#lib/design/components/Stat.svelte';
	import { tr } from '#lib/i18n.svelte.ts';
</script>

<svelte:head><title>{tr('Pregled', 'Overview')} — Mediarr Admin</title></svelte:head>

<div class="ph">
	<div>
		<h1>{tr('Dobrodošli', 'Welcome')}</h1>
		<p>
			{tr(
				'Stanje biblioteke i poslužitelja na jednom mjestu.',
				'Library and server status in one place.'
			)}
		</p>
	</div>
</div>
<div class="stats">
	<Stat label={tr('Korisnici', 'Users')} value="0" />
	<Stat label={tr('Fotke', 'Photos')} value="0" />
	<Stat label={tr('Videi', 'Videos')} value="0" />
	<Stat label={tr('Pohrana', 'Storage')} value="0 GB" pct={0} />
</div>
<div class="grid2">
	<Card title={tr('Poslovi', 'Jobs')}>
		<EmptyState icon="list" text={tr('Nema poslova u redu.', 'There are no queued jobs.')} />
	</Card>
	<Card title={tr('Sustav', 'System')}>
		<Kv label={tr('Verzija', 'Version')} value="0.1.0" />
		<Kv label={tr('Baza', 'Database')} value="PostgreSQL 17" />
	</Card>
</div>
