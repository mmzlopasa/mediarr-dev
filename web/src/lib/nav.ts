import { k, type Key } from '#lib/i18n.svelte.ts';
import type { IconName } from './design/icons';

export type NavItem = {
	path: string;
	icon: IconName;
	label: Key;
	/** What an empty page says; admin pages have none. */
	empty?: Key;
};

export const appNav: NavItem[] = [
	{
		path: '/',
		icon: 'photo',
		label: k('admin.media'),
		empty: k('nav.noPhotosYetAddYour')
	},
	{
		path: '/search',
		icon: 'search',
		label: k('nav.search'),
		empty: k('nav.searchBecomesAvailableOnceYou')
	},
	{
		path: '/explore',
		icon: 'spark',
		label: k('nav.explore'),
		empty: k('nav.nothingToExploreYetAdd')
	},
	{
		path: '/map',
		icon: 'map',
		label: k('admin.settings.map'),
		empty: k('nav.noPhotosWithALocation')
	},
	{
		path: '/people',
		icon: 'users',
		label: k('tv.people'),
		empty: k('nav.noPeopleRecognisedYet')
	},
	{
		path: '/recent',
		icon: 'upload',
		label: k('nav.recentlyAdded'),
		empty: k('nav.nothingHasBeenAddedYet')
	},
	{
		path: '/favorites',
		icon: 'star',
		label: k('accountOverview.favorites'),
		empty: k('nav.noFavoritesYetMarkA')
	},
	{
		path: '/albums',
		icon: 'album',
		label: k('tv.albums'),
		empty: k('nav.noAlbumsYet')
	},
	{
		path: '/shared',
		icon: 'share',
		label: k('nav.shared'),
		empty: k('nav.nothingHasBeenSharedYet')
	},
	{
		path: '/family',
		icon: 'users',
		label: k('family.family'),
		empty: k('nav.theFamilyLibraryIsEmpty')
	},
	{
		path: '/memories',
		icon: 'spark',
		label: k('nav.memories'),
		empty: k('nav.noMemoriesYet')
	},
	{
		path: '/folders',
		icon: 'folder',
		label: k('folders.folders'),
		empty: k('folders.thisFolderIsEmpty')
	},
	{
		path: '/documents',
		icon: 'list',
		label: k('documents.documents'),
		empty: k('nav.noDocumentsYet')
	},
	{
		path: '/duplicates',
		icon: 'copy',
		label: k('duplicates.duplicates'),
		empty: k('duplicates.noSimilarPhotosWereFound')
	},
	{
		path: '/cleanup',
		icon: 'spark',
		label: k('cleanup.cleanUp'),
		empty: k('cleanup.nothingToCleanUpHere')
	},
	{
		path: '/archive',
		icon: 'archive',
		label: k('accountOverview.archive'),
		empty: k('nav.theArchiveIsEmpty')
	},
	{
		path: '/trash',
		icon: 'trash',
		label: k('accountOverview.trash'),
		empty: k('nav.theTrashIsEmpty')
	},
	{
		path: '/vault',
		icon: 'lock',
		label: k('nav.vault'),
		empty: k('nav.theVaultIsEmpty')
	}
];

export const adminNav: NavItem[] = [
	{
		path: '/admin',
		icon: 'grid',
		label: k('admin.overview')
	},
	{
		path: '/admin/users',
		icon: 'users',
		label: k('admin.users.users')
	},
	{
		path: '/admin/jobs',
		icon: 'list',
		label: k('admin.jobs.jobs')
	},
	{
		path: '/admin/storage',
		icon: 'db',
		label: k('admin.storage.storage')
	},
	{
		path: '/admin/settings',
		icon: 'cog',
		label: k('viewer.settings'),
		empty: k('nav.settingsArriveInALater')
	},
	{
		path: '/admin/security',
		icon: 'lock',
		label: k('admin.security.security'),
		empty: k('admin.security.nothingRecordedYet')
	},
	{
		path: '/admin/audit',
		icon: 'shield',
		label: k('admin.audit.activityLog'),
		empty: k('admin.security.nothingRecordedYet')
	},
	{
		path: '/admin/devices',
		icon: 'phone',
		label: k('common.backupDevices')
	},
	{
		path: '/admin/health',
		icon: 'pulse',
		label: k('admin.health.health')
	}
];
