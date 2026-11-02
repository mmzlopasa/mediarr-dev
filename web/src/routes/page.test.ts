import { render } from 'svelte/server';
import { describe, expect, it } from 'vitest';
import Page from './+page.svelte';

describe('home page', () => {
	it('shows the product name', () => {
		const { body } = render(Page);

		expect(body).toContain('Mediarr');
	});
});
