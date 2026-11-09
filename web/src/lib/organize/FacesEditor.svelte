<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type AssetFace, type Person } from '#lib/api.ts';
	import Button from '#lib/design/components/Button.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { t } from '#lib/i18n.svelte.ts';

	const NEW = 'new';
	const SIZE = 48;

	let { assetId }: { assetId: string } = $props();
	let faces = $state<AssetFace[]>();
	let people = $state<Person[]>([]);
	let naming = $state<string>();
	let name = $state('');

	async function load() {
		try {
			const [found, known] = await Promise.all([api.assetFaces(assetId), api.people()]);
			faces = found.faces;
			people = known.people.filter((person) => person.name !== '');
		} catch {
			faces = [];
		}
	}

	onMount(load);

	function failed(cause: unknown) {
		showToast('err', cause instanceof Error ? cause.message : t('common.theActionFailed'));
	}

	async function choose(face: AssetFace, value: string) {
		if (value === NEW) {
			naming = face.id;
			name = '';
			return;
		}
		try {
			await api.assignFace(face.id, { personId: value });
			await load();
		} catch (cause) {
			failed(cause);
		}
	}

	async function saveName(event: SubmitEvent, face: AssetFace) {
		event.preventDefault();
		try {
			await api.assignFace(face.id, { name });
			naming = undefined;
			await load();
		} catch (cause) {
			failed(cause);
		}
	}

	async function remove(face: AssetFace) {
		try {
			await api.removeFace(face.id);
			await load();
		} catch (cause) {
			failed(cause);
		}
	}

	// Shows only the face out of the whole picture.
	function crop(face: AssetFace): string {
		const width = Math.max(face.x2 - face.x1, 0.01);
		const height = Math.max(face.y2 - face.y1, 0.01);
		const left = width < 1 ? (face.x1 / (1 - width)) * 100 : 0;
		const top = height < 1 ? (face.y1 / (1 - height)) * 100 : 0;
		return [
			`width:${SIZE}px`,
			`height:${SIZE}px`,
			`background-image:url('/api/assets/${assetId}/thumbnail?size=large')`,
			`background-size:${100 / width}% ${100 / height}%`,
			`background-position:${left}% ${top}%`
		].join(';');
	}
</script>

{#if !faces}
	<Skeleton height="56px" />
{:else if faces.length > 0}
	<div class="faces">
		<b>{t('facesEditor.people')}</b>
		{#each faces as face (face.id)}
			<div class="face-row">
				<span
					class="face-crop"
					style={crop(face)}
					role="img"
					aria-label={face.person?.name || t('facesEditor.face')}
				></span>
				{#if naming === face.id}
					<form class="face-name" onsubmit={(event) => saveName(event, face)}>
						<!-- svelte-ignore a11y_autofocus -->
						<input
							class="in"
							maxlength="100"
							aria-label={t('common.name2')}
							autofocus
							bind:value={name}
						/>
						<Button type="submit" variant="gold" small>{t('common.save')}</Button>
					</form>
				{:else}
					<select
						class="in"
						aria-label={t('facesEditor.whoThisIs')}
						value={face.person?.id ?? ''}
						onchange={(event) => choose(face, event.currentTarget.value)}
					>
						{#if !face.person?.name}
							<option value={face.person?.id ?? ''}>{t('common.noName')}</option>
						{/if}
						{#each people as person (person.id)}
							<option value={person.id}>{person.name}</option>
						{/each}
						<option value={NEW}>{t('facesEditor.newPerson')}</option>
					</select>
				{/if}
				<Button small onclick={() => remove(face)}>{t('facesEditor.notAPerson')}</Button>
			</div>
		{/each}
	</div>
{/if}
