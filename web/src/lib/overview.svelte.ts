import { onMount } from 'svelte';
import { api, type AdminOverview } from './api.ts';

const POLL_MS = 5000;

/** Live server statistics for the admin pages. `data` stays undefined until the server answers. */
export function liveOverview() {
	const state = $state<{ data?: AdminOverview; failed: boolean }>({ failed: false });

	async function refresh() {
		try {
			state.data = await api.adminOverview();
			state.failed = false;
		} catch {
			state.failed = true;
		}
	}

	onMount(() => {
		refresh();
		const timer = setInterval(refresh, POLL_MS);
		return () => clearInterval(timer);
	});

	return state;
}

export function diskUsedPercent(overview: AdminOverview) {
	if (overview.diskTotalBytes <= 0) return 0;
	return Math.round(
		((overview.diskTotalBytes - overview.diskFreeBytes) / overview.diskTotalBytes) * 100
	);
}
