<script lang="ts">
	import Alert from '#lib/design/components/Alert.svelte';
	import Avatar from '#lib/design/components/Avatar.svelte';
	import Badge from '#lib/design/components/Badge.svelte';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Checkbox from '#lib/design/components/Checkbox.svelte';
	import Dialog from '#lib/design/components/Dialog.svelte';
	import EmptyState from '#lib/design/components/EmptyState.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Input from '#lib/design/components/Input.svelte';
	import Kv from '#lib/design/components/Kv.svelte';
	import Menu from '#lib/design/components/Menu.svelte';
	import Pager from '#lib/design/components/Pager.svelte';
	import PasswordInput from '#lib/design/components/PasswordInput.svelte';
	import Select from '#lib/design/components/Select.svelte';
	import Sheet from '#lib/design/components/Sheet.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import Stat from '#lib/design/components/Stat.svelte';
	import Tabs from '#lib/design/components/Tabs.svelte';
	import ThemeButton from '#lib/design/components/ThemeButton.svelte';
	import Tooltip from '#lib/design/components/Tooltip.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';

	let tab = $state('one');
	let pageNumber = $state(2);
	let dialogOpen = $state(false);
	let sheetOpen = $state(false);
</script>

<svelte:head><title>Components — Mediarr</title></svelte:head>

<main class="main" id="main">
	<div class="ph">
		<div>
			<h1>Komponente</h1>
			<p>Sve komponente design systema.</p>
		</div>
		<div class="ph-a"><ThemeButton /></div>
	</div>

	<div id="zip-components">
		<Card title="Gumbi">
			<div class="btn-row">
				<Button>Obični</Button>
				<Button variant="gold"><Icon name="plus" size={14} /> Zlatni</Button>
				<Button variant="danger">Opasni</Button>
				<Button small>Mali</Button>
				<Button disabled>Isključen</Button>
			</div>
		</Card>
		<Card title="Obrasci">
			<div class="form grid-f">
				<Input label="E-adresa" type="email" placeholder="ime@primjer.hr" hint="Pomoćni tekst" />
				<PasswordInput label="Lozinka" />
				<Select
					label="Uloga"
					options={[
						{ value: 'viewer', label: 'Gledatelj' },
						{ value: 'editor', label: 'Urednik' }
					]}
				/>
				<div class="f"><span>Opcije</span><Checkbox label="Zapamti me" checked /></div>
			</div>
		</Card>
		<Card title="Kartice">
			<Tabs
				label="Primjer"
				tabs={[
					{ id: 'one', label: 'Prva' },
					{ id: 'two', label: 'Druga' }
				]}
				bind:active={tab}
			/>
			<Alert kind="ok">Uspjeh</Alert>
			<Alert kind="warn">Upozorenje</Alert>
			<Alert kind="err">Greška</Alert>
			<div class="btn-row">
				<Badge>Obična</Badge>
				<Badge kind="ok">OK</Badge>
				<Badge kind="warn">Upozorenje</Badge>
				<Badge kind="bad">Loše</Badge>
				<Badge kind="acc">Naglasak</Badge>
				<Avatar initials="DK" />
			</div>
		</Card>
		<div class="stats">
			<Stat label="Fotke" value="1.204" sub="ovaj mjesec 32" />
			<Stat label="Videi" value="86" />
			<Stat label="Pohrana" value="42 GB" pct={42} />
			<Stat label="Disk" value="95 %" pct={95} />
		</div>
		<div class="grid2">
			<Card title="Podaci">
				<Kv label="Verzija" value="0.1.0" />
				<Kv label="Baza" value="PostgreSQL 17" />
				<Bar pct={80} />
			</Card>
			<Card title="Prazno stanje">
				<EmptyState icon="album" text="Još nema albuma.">
					{#snippet cta()}<Button small variant="gold">Novi album</Button>{/snippet}
				</EmptyState>
			</Card>
		</div>
		<Card title="Tablica">
			<div class="tbl-w">
				<table class="tbl">
					<thead><tr><th>Naziv</th><th>Status</th><th class="ta-r">Veličina</th></tr></thead>
					<tbody>
						<tr>
							<td data-l="Naziv"><b>IMG_0001.heic</b></td>
							<td data-l="Status"><Badge kind="ok">Verificirano</Badge></td>
							<td data-l="Veličina" class="ta-r">3,2 MB</td>
						</tr>
						<tr>
							<td data-l="Naziv"><b>VID_0002.mov</b></td>
							<td data-l="Status"><Badge kind="warn">U redu</Badge></td>
							<td data-l="Veličina" class="ta-r">120 MB</td>
						</tr>
					</tbody>
				</table>
			</div>
			<Pager total={120} perPage={20} bind:page={pageNumber} />
		</Card>
	</div>

	<Card title="Dodatne komponente">
		<div class="btn-row">
			<Button onclick={() => (dialogOpen = true)}>Dialog</Button>
			<Button onclick={() => (sheetOpen = true)}>Sheet</Button>
			<Button onclick={() => showToast('ok', 'Spremljeno')}>Toast</Button>
			<Tooltip text="Opis gumba"><Button>Tooltip</Button></Tooltip>
			<Menu label="Izbornik"><p>Sadržaj izbornika</p></Menu>
		</div>
		<hr />
		<div class="form"><Skeleton height="120px" /><Skeleton width="60%" /></div>
		<p class="mute sm-t">Ctrl+K otvara brze naredbe u okviru aplikacije.</p>
	</Card>

	<Dialog title="Primjer dijaloga" bind:open={dialogOpen}>
		<p>Sadržaj dijaloga.</p>
		{#snippet footer()}<Button variant="gold" onclick={() => (dialogOpen = false)}>U redu</Button
			>{/snippet}
	</Dialog>
	<Sheet title="Primjer panela" bind:open={sheetOpen}><p>Sadržaj panela.</p></Sheet>
</main>
