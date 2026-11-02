import { defineConfig } from '@playwright/test';

export default defineConfig({
	testDir: 'bench',
	workers: 1,
	timeout: 180000,
	use: { baseURL: process.env.BENCH_URL, viewport: { width: 1440, height: 900 } }
});
