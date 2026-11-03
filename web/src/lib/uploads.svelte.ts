import { Upload } from 'tus-js-client';

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

let nextId = 1;
let items = $state<UploadItem[]>([]);
let preparing = $state(false);
let preparingTimer = 0;
// Not reactive on purpose: the interface renders `items`, and this only holds the file handles.
// eslint-disable-next-line svelte/prefer-svelte-reactivity
const files = new Map<number, File>();

/** Temporary, development builds only: shows in the dev nginx log what a real phone does. */
export function trace(message: string) {
	if (!import.meta.env.DEV) return;
	navigator.sendBeacon?.(`/__diag?m=${encodeURIComponent(message.slice(0, 400))}`);
}

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
	items = items.filter((item) => item.status === 'queued' || item.status === 'uploading');
}

function update(id: number, changes: Partial<UploadItem>) {
	items = items.map((item) => (item.id === id ? { ...item, ...changes } : item));
}

function fail(id: number, message: string) {
	trace(`fail ${id}: ${message}`);
	files.delete(id);
	update(id, { status: 'failed', error: message });
	pump();
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
	trace(`start ${item.id} ${file.name} ${file.size} ${file.type}`);

	let duplicate = false;
	try {
		const upload = new Upload(file, {
			endpoint: '/api/uploads',
			chunkSize: CHUNK_SIZE,
			retryDelays: RETRY_DELAYS,
			removeFingerprintOnSuccess: true,
			metadata: { filename: file.name, lastModified: String(file.lastModified) },
			onProgress: (loaded, total) => update(item.id, { loaded, total }),
			onAfterResponse: (_request, response) => {
				if (response.getHeader('X-Asset-Duplicate') === 'true') duplicate = true;
			},
			onSuccess: () => {
				trace(`done ${item.id}`);
				files.delete(item.id);
				update(item.id, { status: duplicate ? 'duplicate' : 'done', loaded: file.size });
				pump();
			},
			onError: (error) => fail(item.id, error.message)
		});

		// Continue an upload interrupted earlier, for example by a closed tab.
		const previous = await upload.findPreviousUploads();
		if (previous.length > 0) upload.resumeFromPreviousUpload(previous[0]);
		upload.start();
	} catch (cause) {
		// Without this, a failure here would leave the file on "Uploading" forever.
		fail(item.id, cause instanceof Error ? cause.message : String(cause));
	}
}

export function addUploads(selected: Iterable<File>) {
	setPreparingUpload(false);
	const added: UploadItem[] = [];
	for (const file of selected) {
		const id = nextId++;
		files.set(id, file);
		added.push({ id, name: file.name, loaded: 0, total: file.size, status: 'queued' });
	}
	trace(
		`selected ${added.length}: ${added.map((item) => `${item.name}/${item.total}`).join(', ')}`
	);
	items = [...items, ...added];
	pump();
}
