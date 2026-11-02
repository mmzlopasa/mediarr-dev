import { error } from '@sveltejs/kit';
import { adminNav } from '#lib/nav.ts';
import type { PageLoad } from './$types';

export const load: PageLoad = ({ params }) => {
	const item = adminNav.find((candidate) => candidate.path === `/admin/${params.section}`);
	if (!item) error(404);
	return { item };
};
