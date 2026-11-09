import { expect, type Page } from '@playwright/test';

// Created by `make e2e`, with a password generated for each run.
export const users = {
	admin: 'e2e-admin@example.com',
	user: 'e2e-user@example.com',
	uploader: 'e2e-uploader@example.com',
	owner: 'e2e-owner@example.com',
	member: 'e2e-member@example.com',
	organizer: 'e2e-organizer@example.com',
	stacker: 'e2e-stacker@example.com',
	librarian: 'e2e-librarian@example.com',
	importer: 'e2e-importer@example.com',
	// Only for the test of languages: any other test would save its own language to the account.
	language: 'e2e-language@example.com'
};

export async function signIn(page: Page, who: keyof typeof users) {
	const response = await page.request.post('/api/auth/login', {
		data: { email: users[who], password: process.env.E2E_PASSWORD }
	});
	expect(response.status(), `sign in as ${who}`).toBe(200);
}

// A real JPEG, different every time, so that no two tests share a file.
export function photo(name: string) {
	const jpeg = Buffer.from(
		'/9j/4QC8RXhpZgAASUkqAAgAAAAGABIBAwABAAAAAQAAABoBBQABAAAAVgAAABsBBQABAAAAXgAAACgBAwABAAAAAgAAABMCAwABAAAAAQAAAGmHBAABAAAAZgAAAAAAAAA4YwAA6AMAADhjAADoAwAABgAAkAcABAAAADAyMTABkQcABAAAAAECAwAAoAcABAAAADAxMDABoAMAAQAAAP//AAACoAQAAQAAADwAAAADoAQAAQAAACgAAAAAAAAA/9sAQwAIBgYHBgUIBwcHCQkICgwUDQwLCwwZEhMPFB0aHx4dGhwcICQuJyAiLCMcHCg3KSwwMTQ0NB8nOT04MjwuMzQy/8AACwgAKAA8AQERAP/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/aAAgBAQAAPwBLmGL94Y51N8Nil3kwofoCrd23LJ6kEHvUUcUkixNDJiSDLqJFyCcrgnnHBJ9sjkejhKkp8iSWUS7wCGYkdSD/ABcYI5Pfnrg02KUqjwuqiRmeVi7sxhPBGSeCMYHbqfvVakjVUV2knR5FCOXJwBubnGc/wgdjgdD0Nbb5d6Ijp0CwSL80EhBIJGXViO20Y75xnByBU72qWkamYs4ABUKSDEuASCRjJ+9weuAoJwAVMcd2Fc+UxUbdxnRScdM/MM8YGe+KfAWJiYXCbORIPlJLEsOcE9TngHkYP1pwzSmJzIkYQAsSOwBBIBxz2J2j+Iin3kUq3jxOgkjYeabkDG5Q2Qq8EqcE+nTnIFTQXX7lwJgSFVQr7v3agdyT98cHrnp1xST3P+nQTwpIJG/fGXBYyIVOWAbvgbT/AF7xzPOsEiyPIJMqokdyWfglXBzkgjnnJyF/CSOSUWP2d4VAKGVwFIZFIYf3gCc5wc8An1GblnevpizK0ErmaQy+ZJboxbOBnOTxxgegArPLfYpIt9yHgjbmRYmL4B3457buM8EdRySKk82VbdoZR806I+3AJA3csCxAJxgHHTgA1VVZJLmMxkzqkjAocLk9jtBJPXIxzwc+tTzSRzMsbXjF5TgqQBIPlIzgEYGex4JzzgkEt3PniSIARkqVy+AgHJJ9SvzEcduT81PWQpbXCEySsDtm3SZJH8KgZHBwc7snnJPGTTe5RVUrCqbhlVOTnBOfoccduw+i3Ece9dyT8jIaIoFIyezY6dPTinW0AhkLhXKCX51BPzgqOCTgjpyPQNxV9GkhRneSMPGS4KSYjIOSPuk84BHcYO7nnMNwjXSSQW8ZnhYErNuKhGI7r7qQO/UAkkcV44h5saFMhGHmGBgWmBOCOCM447DHI6Uss0q2oM8vmxpuhjC7mweGzgngcA8kADstNKJutyNwclm3ox2suSTsHGACGz7dcVdfAYRASAI+ZmyBgHJJBXoMkHvwB6iprayW4EjsyIN2EDtECVwDk7iM9eoGPSqYFv8AaBGg+ckscPksDg/K2O+eg75PHd0wzG8cly4jklm5hg5iOCpJBbHAU+owAc+rN5gYQK0kgjXGVlbdxyu3DDsScdxnoTUSvNcgzsiyxjnaVG1doK4bJwMA8knndj3M8acYkhCvuC+USgAP8iSx4PBPB56mOaxjEb5iVvNyrMDheQWT7hGRuzxtGcZ5IFF1GrQSyvLGd0iBY0jxiNQAWXpwAQOPQZxkmmz3VlayG3mhhZ4iULSO5Y4J5JVCP8OnbNf/2Q==',
		'base64'
	);
	return {
		name,
		mimeType: 'image/jpeg',
		buffer: Buffer.concat([jpeg, Buffer.from(`${name}${Math.random()}`)])
	};
}

/** How many photos the timeline shows, once that number has stopped changing. */
export async function settledTiles(page: Page) {
	let last = -1;
	let current = await page.locator('.tl-tile').count();
	for (let round = 0; round < 40 && (current !== last || round < 3); round++) {
		await page.waitForTimeout(250);
		last = current;
		current = await page.locator('.tl-tile').count();
	}
	return current;
}
