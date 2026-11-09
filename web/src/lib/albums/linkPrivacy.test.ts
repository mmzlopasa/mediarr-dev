import { describe, expect, it } from 'vitest';
import type { ShareLink } from '#lib/api.ts';
import { newPrivacy, placeOf, privacyBody, privacyOf, togglePerson } from './linkPrivacy.ts';

const link: ShareLink = {
	id: '1',
	label: 'Family',
	hasPassword: false,
	downloadCount: 0,
	allowDownload: true,
	allowUpload: false,
	uploadOnly: false,
	showLocation: true,
	createdAt: '2026-11-09T10:00:00Z'
};

describe('privacy options', () => {
	it('starts a new link without camera details and without location', () => {
		expect(newPrivacy()).toMatchObject({
			showLocation: false,
			hideFaces: 'none',
			stripCamera: true,
			stripDate: false,
			askName: false
		});
	});

	it('reads what a link says and leaves the rest off', () => {
		expect(privacyOf(link)).toEqual({
			showLocation: true,
			hideFaces: 'none',
			visiblePeople: [],
			stripCamera: false,
			stripDate: false,
			askName: false
		});
		const options = privacyOf({
			...link,
			hideFaces: 'except',
			visiblePeople: ['a'],
			askName: true
		});
		expect(options.hideFaces).toBe('except');
		expect(options.visiblePeople).toEqual(['a']);
		expect(options.askName).toBe(true);
	});

	it('sends the chosen people only when all but them are hidden', () => {
		const chosen = { ...newPrivacy(), visiblePeople: ['a', 'b'] };
		expect(privacyBody({ ...chosen, hideFaces: 'except' }).visiblePeople).toEqual(['a', 'b']);
		expect(privacyBody({ ...chosen, hideFaces: 'all' }).visiblePeople).toEqual([]);
		expect(privacyBody({ ...chosen, hideFaces: 'none' }).visiblePeople).toEqual([]);
	});

	it('turns a person on and off once', () => {
		expect(togglePerson([], 'a', true)).toEqual(['a']);
		expect(togglePerson(['a'], 'a', true)).toEqual(['a']);
		expect(togglePerson(['a', 'b'], 'a', false)).toEqual(['b']);
	});
});

describe('placeOf', () => {
	it('joins the known parts', () => {
		expect(placeOf({ city: 'Split', country: 'Croatia' })).toBe('Split, Croatia');
		expect(placeOf({ country: 'Croatia' })).toBe('Croatia');
		expect(placeOf({ city: ' ', country: '' })).toBeUndefined();
		expect(placeOf({})).toBeUndefined();
	});
});
