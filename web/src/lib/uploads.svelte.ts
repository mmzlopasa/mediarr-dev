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

let nextId = 1;
let items = $state<UploadItem[]>([]);
// Not reactive on purpose: the interface renders `items`, and this only holds the file handles.
// eslint-disable-next-line svelte/prefer-svelte-reactivity
const files = new Map<number, File>();

export function uploads() {
	return items;
}

export function clearFinishedUploads() {
	items = items.filter((item) => item.status === 'queued' || item.status === 'uploading');
}

function update(id: number, changes: Partial<UploadItem>) {
	items = items.map((item) => (item.id === id ? { ...item, ...changes } : item));
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
			files.delete(item.id);
			update(item.id, { status: duplicate ? 'duplicate' : 'done', loaded: file.size });
			pump();
		},
		onError: (error) => {
			files.delete(item.id);
			update(item.id, { status: 'failed', error: error.message });
			pump();
		}
	});

	// Continue an upload interrupted earlier, for example by a closed tab.
	const previous = await upload.findPreviousUploads();
	if (previous.length > 0) upload.resumeFromPreviousUpload(previous[0]);
	upload.start();
}

export function addUploads(selected: Iterable<File>) {
	const added: UploadItem[] = [];
	for (const file of selected) {
		const id = nextId++;
		files.set(id, file);
		added.push({ id, name: file.name, loaded: 0, total: file.size, status: 'queued' });
	}
	items = [...items, ...added];
	pump();
}
