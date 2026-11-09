import type { LibraryExport } from '#lib/api.ts';
import { k, type Key } from '#lib/i18n.svelte.ts';

/** The state of an export in words, and the tone of its chip. */
export const EXPORT_STATUS: Record<LibraryExport['status'], { label: Key; tone: string }> = {
	running: { label: k('export.running'), tone: 'run' },
	done: { label: k('export.ready'), tone: 'ok' },
	failed: { label: k('export.failed'), tone: 'err' },
	cancelled: { label: k('export.cancelled'), tone: '' },
	removed: { label: k('export.removed'), tone: '' }
};

/** How far an export has come, from 0 to 100, by the bytes it has packed. */
export function exportPct(entry: LibraryExport): number {
	if (entry.status === 'done') return 100;
	if (entry.totalBytes > 0) return Math.min(100, (entry.doneBytes / entry.totalBytes) * 100);
	if (entry.totalFiles > 0) return Math.min(100, (entry.doneFiles / entry.totalFiles) * 100);
	return 0;
}

/** Whether something still changes, so the list is asked again. */
export function exportBusy(entries: LibraryExport[]): boolean {
	return entries.some((entry) => entry.status === 'running');
}

/** The address of one part, to download. */
export function exportPartUrl(entry: LibraryExport, number: number): string {
	return `/api/exports/${entry.id}/parts/${number}`;
}
