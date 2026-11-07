import { expect, test } from '@playwright/test';
import { signIn } from './helpers';

// The template is for the whole server, and other tests upload at the same time, so this one never
// keeps one: the server's own tests move files on a database of their own.
test('the storage template is checked as it is typed and shows where real files would go', async ({
	page
}) => {
	await page.addInitScript(() => localStorage.setItem('mediarr_lang', 'en'));
	await signIn(page, 'admin');
	const kept = await (await page.request.get('/api/admin/storage-template')).json();
	expect(kept.template).toBe('');

	await page.goto('/admin/storage');
	const card = page.locator('#storage-template');
	await expect(card.getByText('Storage template')).toBeVisible();
	// Without a template there is nothing to move.
	await expect(card.getByText('Files already here')).toHaveCount(0);

	const field = card.getByLabel('Template');
	await field.fill('{{y}}/{{nope}}-{{filename}}');
	await expect(card.getByRole('alert')).toContainText('not a field');
	await expect(card.getByRole('button', { name: 'Save' })).toBeDisabled();
	await field.fill('{{y}}/{{y}}-{{MM}}-{{dd}}/');
	await card.getByRole('button', { name: '{{filename}}' }).click();
	await field.press('End');
	await field.pressSequentially('.');
	await card.getByRole('button', { name: '{{ext}}' }).click();
	await expect(field).toHaveValue('{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}.{{ext}}');
	const examples = card.getByRole('list', { name: 'Examples' });
	await expect(examples.locator('li').first()).toContainText(/\d{4}\/\d{4}-\d{2}-\d{2}\//);
	await expect(card.getByRole('button', { name: 'Save' })).toBeEnabled();

	const still = await (await page.request.get('/api/admin/storage-template')).json();
	expect(still.template).toBe('');
});
