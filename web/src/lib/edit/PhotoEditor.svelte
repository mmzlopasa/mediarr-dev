<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AssetDetail, type AssetEdits } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';
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
	let look = $state<NonNullable<AssetEdits['filter']> | ''>('');
	let filtersOn = $state(false);
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
		look = edits?.filter ?? '';
		api
			.features()
			.then((features) => (filtersOn = features.filters ?? false))
			.catch(() => undefined);
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
			showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
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
				saturation,
				filter: look || undefined
			})
		);
	const reset = () => finish(() => api.clearEdits(detail.id));

	const corners: Corner[] = ['tl', 'tr', 'bl', 'br'];
	// An approximation for the preview: the server applies the real lookup table.
	const LOOKS: Record<string, string> = {
		mono: 'grayscale(1)',
		warm: 'sepia(0.18) saturate(1.1)',
		cool: 'hue-rotate(12deg) saturate(0.95)',
		vintage: 'sepia(0.35) contrast(0.86) brightness(1.04)',
		vivid: 'saturate(1.35)'
	};
	const filter = $derived(
		`brightness(${100 + brightness / 2}%) contrast(${100 + contrast}%) saturate(${100 + saturation}%) ${look ? LOOKS[look] : ''}`
	);
</script>

<div
	class="editor"
	role="dialog"
	tabindex="-1"
	aria-modal="true"
	aria-label={t('photoEditor.editThePhoto')}
	onpointermove={drag}
	onpointerup={() => (dragging = null)}
>
	<div class="editor-stage">
		{#if failed}
			<p>{t('photoEditor.thePhotoCannotBeLoaded')}</p>
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
								aria-label={t('photoEditor.crop')}
								onpointerdown={(event) => start(event, corner)}
							></button>
						{/each}
					</div>
				{/if}
			</div>
		{/if}
	</div>
	<aside class="editor-tools">
		<h2>{t('photoEditor.editThePhoto')}</h2>
		<p class="alb-meta">
			{t('photoEditor.theOriginalStaysUntouchedAnd')}
		</p>
		<Button onclick={turn}><Icon name="sync" size={14} /> {t('photoEditor.rotate')}</Button>
		<label
			>{t('photoEditor.brightness')}
			<input type="range" min="-100" max="100" bind:value={brightness} /></label
		>
		<label
			>{t('photoEditor.contrast')}
			<input type="range" min="-100" max="100" bind:value={contrast} /></label
		>
		<label
			>{t('photoEditor.saturation')}
			<input type="range" min="-100" max="100" bind:value={saturation} /></label
		>
		{#if filtersOn}
			<label
				>{t('photoEditor.filter')}
				<select bind:value={look}>
					<option value="">{t('photoEditor.none')}</option>
					<option value="mono">{t('photoEditor.blackAndWhite')}</option>
					<option value="warm">{t('photoEditor.warm')}</option>
					<option value="cool">{t('photoEditor.cool')}</option>
					<option value="vintage">{t('photoEditor.vintage')}</option>
					<option value="vivid">{t('photoEditor.vivid')}</option>
				</select></label
			>
		{/if}
		<div class="editor-acts">
			<Button variant="gold" disabled={busy} onclick={save}>{t('common.save')}</Button>
			{#if detail.edits}
				<Button disabled={busy} onclick={reset}>{t('photoEditor.backToTheOriginal')}</Button>
			{/if}
			<Button disabled={busy} onclick={onClose}>{t('common.cancel')}</Button>
		</div>
	</aside>
</div>
