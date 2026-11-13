// Sending photos and videos to other apps from the browser, where it can (mostly on phones). The
// server gives each as its original, or as a smaller JPEG for messages.

const SMALL_KEY = 'mediarr_share_small';

/** Whether this browser can hand files to other apps. */
export function canShareFiles(): boolean {
	if (typeof navigator === 'undefined' || !navigator.canShare) return false;
	try {
		return navigator.canShare({ files: [new File([''], 'a.jpg', { type: 'image/jpeg' })] });
	} catch {
		return false;
	}
}

/** The choice between the original and a smaller file, kept for next time. */
export function prefersSmall(): boolean {
	return typeof localStorage !== 'undefined' && localStorage.getItem(SMALL_KEY) === '1';
}

export function rememberSmall(small: boolean) {
	localStorage.setItem(SMALL_KEY, small ? '1' : '0');
}

/** The name a file comes with, from Content-Disposition. */
export function fileNameFrom(disposition: string | null, fallback: string): string {
	const encoded = /filename\*=UTF-8''([^;]+)/i.exec(disposition ?? '');
	if (encoded) return decodeURIComponent(encoded[1]);
	const plain = /filename="?([^";]+)"?/i.exec(disposition ?? '');
	return plain?.[1] ?? fallback;
}

/** Fetches the files and opens the system's sheet to send them. */
export async function shareAssets(ids: string[], small: boolean, base = '/api') {
	const files: File[] = [];
	for (const id of ids) {
		const response = await fetch(`${base}/assets/${id}/share${small ? '?small=true' : ''}`);
		if (!response.ok) throw new Error(`The server answered ${response.status}`);
		const blob = await response.blob();
		const name = fileNameFrom(response.headers.get('Content-Disposition'), id);
		files.push(new File([blob], name, { type: blob.type || 'application/octet-stream' }));
	}
	await navigator.share({ files });
}
