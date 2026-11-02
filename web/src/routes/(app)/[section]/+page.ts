import { error } from '@sveltejs/kit';
import { appNav } from '#lib/nav.ts';
import type { PageLoad } from './$types';

export const load: PageLoad = ({ params }) => {
	const item = appNav.find((candidate) => candidate.path === `/${params.section}`);
	if (!item) error(404);
	return { item };
};
