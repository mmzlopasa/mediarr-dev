import { Upload } from 'tus-js-client';

// Large exports are uploaded in pieces, each small enough to lose little when a connection drops.
const CHUNK_SIZE = 50 * 1024 * 1024;
const RETRY_DELAYS = [0, 1000, 3000, 5000, 10000, 30000];

/**
 * Uploads one ZIP file of an export to its import. Choosing the same file again for the same
 * import goes on from where it stopped, even after the browser was closed.
 */
export function uploadImportPart(
	importId: string,
	file: File,
	onProgress: (loaded: number, total: number) => void
): { done: Promise<void>; abort: () => void } {
	let upload: Upload | undefined;
	const done = new Promise<void>((resolve, reject) => {
		upload = new Upload(file, {
			endpoint: '/api/uploads',
			chunkSize: CHUNK_SIZE,
			retryDelays: RETRY_DELAYS,
			removeFingerprintOnSuccess: true,
			// The import is part of what makes the file this file, so a ZIP file chosen for another
			// import does not continue this one's upload.
			fingerprint: async (chosen) =>
				['mediarr-import', importId, chosen.name, chosen.size, chosen.lastModified].join('/'),
			metadata: { filename: file.name, importId },
			onProgress,
			onSuccess: () => resolve(),
			onError: (error) => {
				const response = (error as { originalResponse?: { getBody(): string } }).originalResponse;
				let message = error.message;
				try {
					message = JSON.parse(response?.getBody() ?? '').message ?? message;
				} catch {
					message = response?.getBody() || message;
				}
				// tus answers in plain text, starting with its error code.
				reject(new Error(message.replace(/^ERR_[A-Z_]+:\s*/, '').trim()));
			}
		});
		upload
			.findPreviousUploads()
			.then((previous) => {
				if (previous.length) upload?.resumeFromPreviousUpload(previous[0]);
				upload?.start();
			})
			.catch(reject);
	});
	return { done, abort: () => void upload?.abort() };
}
