import { redirect } from '@sveltejs/kit';
import { api } from '#lib/api.ts';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ fetch, url, depends }) => {
	depends('app:session');
	const status = await api.status(fetch);
	if (status.setupRequired) redirect(307, '/setup');
	if (!status.user) redirect(307, `/login?next=${encodeURIComponent(url.pathname + url.search)}`);
	return { user: status.user };
};
