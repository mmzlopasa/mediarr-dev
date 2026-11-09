// What the bench checks and its limits. The first four are the performance targets of the project;
// report.mjs enforces all of them, and fails on one that was not measured.
export const CHECKS = [
	{ key: 'firstView', label: 'Timeline first view, 100k assets', limit: 1000, unit: 'ms' },
	{ key: 'smartSearch', label: 'Smart search p95', limit: 300, unit: 'ms' },
	{ key: 'idleRam', label: 'Server idle RAM, without ML', limit: 300, unit: 'MB' },
	{ key: 'cleanup', label: 'Clean up counts, GET /api/cleanup', limit: 300, unit: 'ms' },
	{ key: 'filteredSearch', label: 'Search with filters p95', limit: 300, unit: 'ms' },
	{ key: 'jump', label: 'Jump to 70% of the timeline', limit: 2000, unit: 'ms' },
	// Frame rates on shared runners are too noisy to fail a build, so CI sets BENCH_SKIP_FPS.
	{
		key: 'fps',
		label: 'Scrolling',
		limit: 55,
		unit: 'fps',
		atLeast: true,
		skipEnv: 'BENCH_SKIP_FPS'
	}
];
