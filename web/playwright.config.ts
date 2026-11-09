import { defineConfig } from '@playwright/test';

export default defineConfig({
	// The whole run shares a server with other apps; a page can take a while without being wrong.
	expect: { timeout: 15_000 },
	testDir: 'e2e',
	use: {
		baseURL: process.env.E2E_BASE_URL ?? 'http://127.0.0.1:9852',
		// Motion has its own test (e2e/motion.test.ts); everything else checks the page at rest.
		reducedMotion: 'reduce'
	}
});
