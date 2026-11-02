import { redirect } from '@sveltejs/kit';
import { api } from '#lib/api.ts';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch }) => {
	const status = await api.status(fetch);
	if (!status.setupRequired) redirect(307, '/login');
};
