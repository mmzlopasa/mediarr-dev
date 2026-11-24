import type { Upload } from 'tus-js-client';
import { showToast } from '#lib/design/components/toast.svelte.ts';
import { t } from '#lib/i18n.svelte.ts';

export type UploadStatus = 'queued' | 'uploading' | 'done' | 'duplicate' | 'failed';

export type UploadItem = {
	id: number;
	name: string;
	loaded: number;
	total: number;
	status: UploadStatus;
	error?: string;
};

const MAX_PARALLEL = 3;
// Small enough that a proxy buffering requests loses little when a connection drops.
const CHUNK_SIZE = 50 * 1024 * 1024;
const RETRY_DELAYS = [0, 1000, 3000, 5000, 10000];
const PREPARING_TIMEOUT_MS = 180000;
// A sent file stays a moment with its tick, then goes; one that failed stays, with its error.
const DONE_LINGER_MS = 1500;

let nextId = 1;
let items = $state<UploadItem[]>([]);
let preparing = $state(false);
let preparingTimer = 0;
// What this round of uploads did, said once when the last file is in.
let sent = 0;
let existed = 0;
// Not reactive on purpose: the interface renders `items`, and this only holds the file handles.
// eslint-disable-next-line svelte/prefer-svelte-reactivity
const files = new Map<number, File>();
// eslint-disable-next-line svelte/prefer-svelte-reactivity
const albums = new Map<number, string>();
// The uploads under way, so that one can be stopped.
// eslint-disable-next-line svelte/prefer-svelte-reactivity
const running = new Map<number, Upload>();
// The upload code is fetched with the first file, not with every page.
let tus: Promise<typeof import('tus-js-client')> | undefined;

export function uploads() {
	return items;
}

export function isPreparingUpload() {
	return preparing;
}

/** iOS copies and converts photos after the picker closes, which can take a while. */
export function setPreparingUpload(value: boolean) {
	preparing = value;
	clearTimeout(preparingTimer);
	if (value) preparingTimer = window.setTimeout(() => (preparing = false), PREPARING_TIMEOUT_MS);
}

export function clearFinishedUploads() {
	items = items.filter((item) => {
		const keep = item.status === 'queued' || item.status === 'uploading';
		if (!keep) forget(item.id);
		return keep;
	});
}

function forget(id: number) {
	files.delete(id);
	albums.delete(id);
	running.delete(id);
}

/** Sends a failed file again, from where it stopped if the server kept the part it had. */
export function retryUpload(id: number) {
	if (!files.has(id)) return;
	update(id, { status: 'queued', error: undefined });
	pump();
}

/** Stops a file that is waiting or on its way; what the server has of it is thrown away. */
export function cancelUpload(id: number) {
	const upload = running.get(id);
	forget(id);
	items = items.filter((item) => item.id !== id);
	if (upload) void upload.abort(true).catch(() => undefined);
	pump();
	finishRound();
}

function finishRound() {
	if (items.some((item) => item.status === 'queued' || item.status === 'uploading')) return;
	if (sent + existed === 0) return;
	const parts = [t('uploads.uploadedSent', { sent })];
	if (existed) parts.push(t('uploads.alreadyExistedExisted', { existed }));
	showToast('ok', parts.join(' · '));
	sent = 0;
	existed = 0;
}

function update(id: number, changes: Partial<UploadItem>) {
	items = items.map((item) => (item.id === id ? { ...item, ...changes } : item));
}

function fail(id: number, message: string) {
	// The file is kept, so that it can be sent again.
	running.delete(id);
	if (!items.some((item) => item.id === id)) return;
	update(id, { status: 'failed', error: message });
	pump();
	finishRound();
}

function pump() {
	const running = items.filter((item) => item.status === 'uploading').length;
	const queued = items.filter((item) => item.status === 'queued');
	for (const item of queued.slice(0, Math.max(0, MAX_PARALLEL - running))) start(item);
}

async function start(item: UploadItem) {
	const file = files.get(item.id);
	if (!file) return;
	update(item.id, { status: 'uploading' });

	let duplicate = false;
	try {
		tus ??= import('tus-js-client');
		const { Upload } = await tus.catch((cause) => {
			tus = undefined;
			throw cause;
		});
		// Stopped while the upload code was on its way.
		if (!files.has(item.id)) return;
		const upload = new Upload(file, {
			endpoint: '/api/uploads',
			chunkSize: CHUNK_SIZE,
			retryDelays: RETRY_DELAYS,
			removeFingerprintOnSuccess: true,
			metadata: {
				filename: file.name,
				lastModified: String(file.lastModified),
				...(albums.has(item.id) ? { albumId: albums.get(item.id) as string } : {})
			},
			onProgress: (loaded, total) => update(item.id, { loaded, total }),
			onAfterResponse: (_request, response) => {
				if (response.getHeader('X-Asset-Duplicate') === 'true') duplicate = true;
			},
			onSuccess: () => {
				forget(item.id);
				update(item.id, { status: duplicate ? 'duplicate' : 'done', loaded: file.size });
				if (duplicate) existed += 1;
				else sent += 1;
				window.setTimeout(() => {
					items = items.filter((entry) => entry.id !== item.id);
				}, DONE_LINGER_MS);
				pump();
				finishRound();
			},
			onError: (error) => fail(item.id, error.message)
		});

		// Continue an upload interrupted earlier, for example by a closed tab.
		const previous = await upload.findPreviousUploads();
		if (!files.has(item.id)) return;
		if (previous.length > 0) upload.resumeFromPreviousUpload(previous[0]);
		running.set(item.id, upload);
		upload.start();
	} catch (cause) {
		// Without this, a failure here would leave the file on "Uploading" forever.
		fail(item.id, cause instanceof Error ? cause.message : String(cause));
	}
}

export function addUploads(selected: Iterable<File>, albumId?: string) {
	setPreparingUpload(false);
	const added: UploadItem[] = [];
	for (const file of selected) {
		const id = nextId++;
		files.set(id, file);
		if (albumId) albums.set(id, albumId);
		added.push({ id, name: file.name, loaded: 0, total: file.size, status: 'queued' });
	}
	items = [...items, ...added];
	pump();
}
