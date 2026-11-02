export type ToastKind = 'ok' | 'warn' | 'err';
export type Toast = { id: number; kind: ToastKind; text: string };

const LIFETIME_MS = 4000;

let nextId = 1;
let items = $state<Toast[]>([]);

export function toasts() {
	return items;
}

export function dismissToast(id: number) {
	items = items.filter((toast) => toast.id !== id);
}

export function showToast(kind: ToastKind, text: string) {
	const id = nextId++;
	items = [...items, { id, kind, text }];
	setTimeout(() => dismissToast(id), LIFETIME_MS);
	return id;
}
