import { expect, type Page } from '@playwright/test';

// Created by `make e2e`, with a password generated for each run.
export const users = {
	admin: 'e2e-admin@example.com',
	user: 'e2e-user@example.com',
	uploader: 'e2e-uploader@example.com'
};

export async function signIn(page: Page, who: keyof typeof users) {
	const response = await page.request.post('/api/auth/login', {
		data: { email: users[who], password: process.env.E2E_PASSWORD }
	});
	expect(response.status(), `sign in as ${who}`).toBe(200);
}
