<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AssetDetail } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';
	import { moveCrop, turnCrop, wholePicture, type Crop, type Corner } from './crop.ts';

	const WAIT_MS = 500;
	const WAIT_TRIES = 120;

	let {
		detail,
		onClose,
		onSaved
	}: {
		detail: AssetDetail;
		onClose: () => void;
		onSaved: () => void;
	} = $props();

	let rotate = $state(0);
	let crop = $state<Crop>({ ...wholePicture });
	let brightness = $state(0);
	let contrast = $state(0);
	let saturation = $state(0);
	let picture = $state<HTMLImageElement>();
	let canvas = $state<HTMLCanvasElement>();
	let busy = $state(false);
	let failed = $state(false);

	onMount(() => {
		const edits = detail.edits;
		rotate = edits?.rotate ?? 0;
		crop = edits?.crop ? { ...edits.crop } : { ...wholePicture };
		brightness = edits?.brightness ?? 0;
		contrast = edits?.contrast ?? 0;
		saturation = edits?.saturation ?? 0;
		const image = new Image();
		image.onload = () => (picture = image);
		image.onerror = () => (failed = true);
		image.src = `/api/assets/${detail.id}/thumbnail?size=source`;
	});

	$effect(() => {
		const image = picture;
		const target = canvas;
		if (!image || !target) return;
		const sideways = rotate % 180 !== 0;
		target.width = sideways ? image.naturalHeight : image.naturalWidth;
		target.height = sideways ? image.naturalWidth : image.naturalHeight;
		const context = target.getContext('2d');
		if (!context) return;
		context.translate(target.width / 2, target.height / 2);
		context.rotate((rotate * Math.PI) / 180);
		context.drawImage(image, -image.naturalWidth / 2, -image.naturalHeight / 2);
	});

	function turn() {
		rotate = (rotate + 90) % 360;
		crop = turnCrop(crop);
	}

	let dragging: Corner | null = null;

	function drag(event: PointerEvent) {
		if (!dragging || !canvas) return;
		const box = canvas.getBoundingClientRect();
		crop = moveCrop(
			crop,
			dragging,
			(event.clientX - box.left) / box.width,
			(event.clientY - box.top) / box.height
		);
	}

	function start(event: PointerEvent, corner: Corner) {
		dragging = corner;
		(event.currentTarget as HTMLElement).setPointerCapture(event.pointerId);
		event.preventDefault();
	}

	// The old previews stay in the browser's cache for a day unless they are asked for again.
	async function refreshPreviews() {
		await Promise.all(
			['', '?size=large', '?size=full'].map((size) =>
				fetch(`/api/assets/${detail.id}/thumbnail${size}`, { cache: 'reload' }).catch(() => null)
			)
		);
	}

	async function finish(action: () => Promise<void>) {
		busy = true;
		try {
			await action();
			for (let attempt = 0; attempt < WAIT_TRIES; attempt += 1) {
				const current = await api.asset(detail.id);
				if (!current.isEditing) break;
				await new Promise((resolve) => setTimeout(resolve, WAIT_MS));
			}
			await refreshPreviews();
			onSaved();
		} catch (cause) {
			showToast(
				'err',
				cause instanceof Error ? cause.message : tr('Radnja nije uspjela.', 'The action failed.')
			);
			busy = false;
		}
	}

	const isWhole = $derived(crop.x === 0 && crop.y === 0 && crop.width === 1 && crop.height === 1);

	const save = () =>
		finish(() =>
			api.setEdits(detail.id, {
				rotate,
				crop: isWhole ? undefined : crop,
				brightness,
				contrast,
				saturation
			})
		);
	const reset = () => finish(() => api.clearEdits(detail.id));

	const corners: Corner[] = ['tl', 'tr', 'bl', 'br'];
	const filter = $derived(
		`brightness(${100 + brightness / 2}%) contrast(${100 + contrast}%) saturate(${100 + saturation}%)`
	);
</script>

<div
	class="editor"
	role="dialog"
	aria-modal="true"
	aria-label={tr('Uredi fotku', 'Edit the photo')}
	onpointermove={drag}
	onpointerup={() => (dragging = null)}
>
	<div class="editor-stage">
		{#if failed}
			<p>{tr('Fotka se ne može učitati.', 'The photo cannot be loaded.')}</p>
		{:else}
			<div class="editor-frame">
				<canvas bind:this={canvas} style="filter:{filter}"></canvas>
				{#if picture}
					<div
						class="editor-crop"
						style="left:{crop.x * 100}%;top:{crop.y * 100}%;width:{crop.width *
							100}%;height:{crop.height * 100}%"
					>
						{#each corners as corner (corner)}
							<button
								type="button"
								class="editor-handle {corner}"
								aria-label={tr('Obrezivanje', 'Crop')}
								onpointerdown={(event) => start(event, corner)}
							></button>
						{/each}
					</div>
				{/if}
			</div>
		{/if}
	</div>
	<aside class="editor-tools">
		<h2>{tr('Uredi fotku', 'Edit the photo')}</h2>
		<p class="alb-meta">
			{tr(
				'Original ostaje netaknut, a izmjene možete uvijek poništiti.',
				'The original stays untouched, and you can always undo the edits.'
			)}
		</p>
		<Button onclick={turn}><Icon name="sync" size={14} /> {tr('Okreni', 'Rotate')}</Button>
		<label
			>{tr('Svjetlina', 'Brightness')}
			<input type="range" min="-100" max="100" bind:value={brightness} /></label
		>
		<label
			>{tr('Kontrast', 'Contrast')}
			<input type="range" min="-100" max="100" bind:value={contrast} /></label
		>
		<label
			>{tr('Zasićenost', 'Saturation')}
			<input type="range" min="-100" max="100" bind:value={saturation} /></label
		>
		<div class="editor-acts">
			<Button variant="gold" disabled={busy} onclick={save}>{tr('Spremi', 'Save')}</Button>
			{#if detail.edits}
				<Button disabled={busy} onclick={reset}
					>{tr('Vrati original', 'Back to the original')}</Button
				>
			{/if}
			<Button disabled={busy} onclick={onClose}>{tr('Odustani', 'Cancel')}</Button>
		</div>
	</aside>
</div>
