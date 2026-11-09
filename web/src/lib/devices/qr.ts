/** The address inside a sign-in code, with the server a phone can reach instead of this one. */
export function withServer(link: string, server: string): string {
	const url = new URL(link);
	url.searchParams.set('server', server.trim().replace(/\/+$/, ''));
	return url.toString();
}

/** A browser on the server itself has an address no phone can reach. */
export function onlyHere(server: string | undefined): boolean {
	if (!server) return true;
	const host = new URL(server).hostname;
	return host === 'localhost' || host === '[::1]' || host.startsWith('127.');
}

/** Minutes and seconds left, as the countdown shows them. */
export function left(expiresAt: string, now: number): string {
	const seconds = Math.max(0, Math.round((Date.parse(expiresAt) - now) / 1000));
	return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}
