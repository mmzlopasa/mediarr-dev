// What went wrong, in the words a person needs: a page that is not there, a server that is down
// or in maintenance, a connection that is gone, or a fault on the server.

export type ErrorKind = 'notFound' | 'unavailable' | 'offline' | 'server';

/** Statuses that mean the server is not there right now: starting, updating or in maintenance. */
const UNAVAILABLE = new Set([502, 503, 504]);

/** From a status of the server, or of a page, and whether the browser is online. */
export function errorKind(status: number, online = true): ErrorKind {
	if (status === 404) return 'notFound';
	if (!online) return 'offline';
	if (UNAVAILABLE.has(status)) return 'unavailable';
	return 'server';
}

/** From something thrown while a page loaded: an answer of the server, or no answer at all. */
export function kindOfFailure(cause: unknown, online = true): ErrorKind {
	if (!online) return 'offline';
	const status = (cause as { status?: unknown } | null)?.status;
	if (typeof status === 'number') return errorKind(status, online);
	// fetch rejects with a TypeError when no answer came.
	if (cause instanceof TypeError) return 'offline';
	return 'server';
}
