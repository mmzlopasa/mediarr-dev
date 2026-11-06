<script lang="ts">
	import { kenBurns } from '#lib/motion/actions.ts';
	import { onMount, tick } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import {
		albumSource,
		api,
		personSource,
		type Album,
		type Memory,
		type Person,
		type TimelineSource
	} from '#lib/api.ts';
	import Brand from '#lib/design/components/Brand.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { memoryTitle } from '#lib/organize/memories.ts';
	import { lang, tr } from '#lib/i18n.svelte.ts';
	import { thumbUrl } from '#lib/timeline/blur.ts';
	import { itemCount } from '#lib/timeline/layout.ts';

	// The living room: one big picture, a few rows, and a remote with arrows, OK and back.
	const SHOW_MS = 6000;
	const ROW_SIZE = 16;

	type Card = {
		key: string;
		title: string;
		sub: string;
		cover: string;
		round?: boolean;
		play: () => Promise<string[]>;
	};
	type Row = { title: string; cards: Card[] };

	let rows = $state<Row[]>();
	let failed = $state(false);
	let row = $state(0);
	let column = $state(0);
	let show = $state<{ ids: string[]; index: number; playing: boolean }>();
	let now = $state(new Date());
	let cards = $state<HTMLElement[][]>([]);

	const focused = $derived(rows?.[row]?.cards[column]);

	function today() {
		const date = new Date();
		const pad = (value: number) => String(value).padStart(2, '0');
		return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
	}

	async function photosOf(source: TimelineSource) {
		const ids: string[] = [];
		const { buckets } = await source.buckets();
		for (const bucket of buckets) {
			const { items } = await source.bucket(bucket.month);
			ids.push(...items.filter((item) => item.kind === 'photo').map((item) => item.id));
		}
		return ids;
	}

	function memoryCard(memory: Memory): Card {
		const photos = memory.items.filter((item) => item.kind === 'photo');
		return {
			key: `m-${memory.kind}-${memory.title}`,
			title: memoryTitle(memory),
			sub: itemCount(memory.items.length, lang()),
			cover: thumbUrl('/api', memory.items[0].id, memory.items[0].blurhash, 'large'),
			play: async () => photos.map((item) => item.id)
		};
	}

	function albumCard(album: Album): Card {
		return {
			key: `a-${album.id}`,
			title: album.title,
			sub: itemCount(album.assetCount, lang()),
			cover: album.coverAssetId ? thumbUrl('/api', album.coverAssetId, null, 'large') : '',
			play: () => photosOf(albumSource(album.id))
		};
	}

	function personCard(person: Person): Card {
		return {
			key: `p-${person.id}`,
			title: person.name,
			sub: itemCount(person.assetCount, lang()),
			cover: `/api/people/${person.id}/thumbnail`,
			round: true,
			play: () => photosOf(personSource(person.id))
		};
	}

	async function load() {
		try {
			const [memories, albums, people] = await Promise.all([
				api.memories(today()),
				api.albums(),
				api.people()
			]);
			rows = [
				{
					title: tr('Uspomene', 'Memories'),
					cards: memories.filter((memory) => memory.items.length).map(memoryCard)
				},
				{
					title: tr('Albumi', 'Albums'),
					cards: albums
						.filter((album) => album.assetCount > 0)
						.slice(0, ROW_SIZE)
						.map(albumCard)
				},
				{
					title: tr('Ljudi', 'People'),
					cards: people.people
						.filter((person) => person.name && !person.hidden)
						.slice(0, ROW_SIZE)
						.map(personCard)
				}
			].filter((entry) => entry.cards.length > 0);
			cards = rows.map(() => []);
			await tick();
			cards[0]?.[0]?.focus();
		} catch {
			failed = true;
		}
	}

	onMount(() => {
		load();
		const clock = setInterval(() => (now = new Date()), 30000);
		return () => clearInterval(clock);
	});

	$effect(() => {
		if (!show?.playing) return;
		const timer = setInterval(() => {
			if (show) show.index = (show.index + 1) % show.ids.length;
		}, SHOW_MS);
		return () => clearInterval(timer);
	});

	function move(toRow: number, toColumn: number) {
		if (!rows?.length) return;
		row = Math.max(0, Math.min(rows.length - 1, toRow));
		column = Math.max(0, Math.min(rows[row].cards.length - 1, toColumn));
		cards[row]?.[column]?.focus();
	}

	async function open(card: Card) {
		const ids = await card.play().catch(() => []);
		if (ids.length) show = { ids, index: 0, playing: true };
	}

	const BACK = ['Escape', 'Backspace', 'GoBack', 'BrowserBack'];

	// Every move is immediate: the remote is pressed often, and waiting for motion would feel slow.
	function key(event: KeyboardEvent) {
		if (show) {
			if (BACK.includes(event.key)) show = undefined;
			else if (event.key === 'ArrowRight') show.index = (show.index + 1) % show.ids.length;
			else if (event.key === 'ArrowLeft')
				show.index = (show.index - 1 + show.ids.length) % show.ids.length;
			else if (event.key === 'Enter' || event.key === ' ') show.playing = !show.playing;
			else return;
			event.preventDefault();
			return;
		}
		if (event.key === 'ArrowRight') move(row, column + 1);
		else if (event.key === 'ArrowLeft') move(row, column - 1);
		else if (event.key === 'ArrowDown') move(row + 1, 0);
		else if (event.key === 'ArrowUp') move(row - 1, 0);
		else if (BACK.includes(event.key)) goto(resolve('/(app)'));
		else return;
		event.preventDefault();
	}
</script>

<svelte:head><title>{tr('TV', 'TV')} — Mediarr</title></svelte:head>
<svelte:window onkeydown={key} />

<main class="tv">
	{#if focused?.cover}
		<div class="tv-hero" style="background-image:url({focused.cover})" aria-hidden="true"></div>
	{/if}
	<header class="tv-top">
		<span class="logo" role="img" aria-label="Mediarr"><Brand /></span>
		<span class="tv-clock"
			>{now.toLocaleTimeString(lang(), { hour: '2-digit', minute: '2-digit' })}</span
		>
	</header>

	{#if failed}
		<p class="tv-note">{tr('Podaci se ne mogu učitati.', 'This could not be loaded.')}</p>
	{:else if !rows}
		<div class="tv-wait"><Skeleton height="240px" /></div>
	{:else if rows.length === 0}
		<p class="tv-note">
			{tr('Još nema ničega za pogledati. Dodajte fotke.', 'Nothing to watch yet. Add some photos.')}
		</p>
	{:else}
		<div class="tv-lead">
			<h1>{focused?.title}</h1>
			<p>{focused?.sub} · {tr('OK pušta, natrag izlazi', 'OK plays, back leaves')}</p>
		</div>
		{#each rows as entry, r (entry.title)}
			<section class="tv-row" aria-label={entry.title}>
				<h2>{entry.title}</h2>
				<div class="tv-cards">
					{#each entry.cards as card, c (card.key)}
						<button
							type="button"
							class="tv-card"
							class:round={card.round}
							bind:this={cards[r][c]}
							onfocus={() => {
								row = r;
								column = c;
							}}
							onclick={() => open(card)}
						>
							{#if card.cover}<img src={card.cover} alt="" loading="lazy" />{/if}
							<span>{card.title}</span>
						</button>
					{/each}
				</div>
			</section>
		{/each}
	{/if}

	{#if show}
		<div class="tv-show" role="dialog" aria-label={tr('Prikaz fotki', 'Slideshow')}>
			{#key show.ids[show.index]}
				<img
					src={thumbUrl('/api', show.ids[show.index], null, 'large')}
					alt=""
					use:kenBurns={{ seconds: SHOW_MS / 1000, turn: show.index }}
				/>
			{/key}
			<p class="tv-show-n">
				{show.index + 1} / {show.ids.length}{show.playing
					? ''
					: ` · ${tr('zaustavljeno', 'paused')}`}
			</p>
		</div>
	{/if}
</main>
