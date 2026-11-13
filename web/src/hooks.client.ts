import { kindOfFailure, type ErrorKind } from '#lib/errors.ts';

// Without this every failure while loading a page would look the same: the error page says whether
// the server is down, the connection is gone or something broke.
export function handleError({
	error,
	status,
	message
}: {
	error: unknown;
	status: number;
	message: string;
}): { message: string; kind: ErrorKind } {
	const online = typeof navigator === 'undefined' ? true : navigator.onLine;
	return { message, kind: status === 404 ? 'notFound' : kindOfFailure(error, online) };
}
