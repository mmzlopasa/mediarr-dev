import { redirect } from '@sveltejs/kit';
import { api } from '#lib/api.ts';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ fetch, url, depends, untrack }) => {
	// The address is read only to come back to it after signing in. Read tracked, it would ask the
	// server who is signed in again on every navigation.
	const here = untrack(() => url.pathname + url.search);
	depends('app:session');
	const status = await api.status(fetch);
	if (status.setupRequired) redirect(307, '/setup');
	if (!status.user) redirect(307, `/login?next=${encodeURIComponent(here)}`);
	if (!status.user.isAdmin) redirect(307, '/');
	return { user: status.user };
};
