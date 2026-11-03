import type { IconName } from './design/icons';

export type NavItem = {
	path: string;
	icon: IconName;
	hr: string;
	en: string;
	emptyHr: string;
	emptyEn: string;
};

export const appNav: NavItem[] = [
	{
		path: '/',
		icon: 'photo',
		hr: 'Mediji',
		en: 'Media',
		emptyHr: 'Još nema fotki. Dodajte prve gumbom Upload.',
		emptyEn: 'No photos yet. Add your first ones with the Upload button.'
	},
	{
		path: '/search',
		icon: 'search',
		hr: 'Pretraga',
		en: 'Search',
		emptyHr: 'Pretraga će biti dostupna kad dodate fotke.',
		emptyEn: 'Search becomes available once you add photos.'
	},
	{
		path: '/map',
		icon: 'map',
		hr: 'Karta',
		en: 'Map',
		emptyHr: 'Još nema fotki s lokacijom.',
		emptyEn: 'No photos with a location yet.'
	},
	{
		path: '/people',
		icon: 'users',
		hr: 'Ljudi',
		en: 'People',
		emptyHr: 'Još nema prepoznatih osoba.',
		emptyEn: 'No people recognised yet.'
	},
	{
		path: '/albums',
		icon: 'album',
		hr: 'Albumi',
		en: 'Albums',
		emptyHr: 'Još nema albuma.',
		emptyEn: 'No albums yet.'
	},
	{
		path: '/shared',
		icon: 'share',
		hr: 'Dijeljeno',
		en: 'Shared',
		emptyHr: 'Još ništa nije podijeljeno.',
		emptyEn: 'Nothing has been shared yet.'
	},
	{
		path: '/memories',
		icon: 'spark',
		hr: 'Memories',
		en: 'Memories',
		emptyHr: 'Još nema uspomena.',
		emptyEn: 'No memories yet.'
	},
	{
		path: '/duplicates',
		icon: 'copy',
		hr: 'Duplikati',
		en: 'Duplicates',
		emptyHr: 'Nisu pronađene slične fotke.',
		emptyEn: 'No similar photos were found.'
	},
	{
		path: '/archive',
		icon: 'archive',
		hr: 'Arhiva',
		en: 'Archive',
		emptyHr: 'Arhiva je prazna.',
		emptyEn: 'The archive is empty.'
	},
	{
		path: '/trash',
		icon: 'trash',
		hr: 'Smeće',
		en: 'Trash',
		emptyHr: 'Smeće je prazno.',
		emptyEn: 'The trash is empty.'
	},
	{
		path: '/vault',
		icon: 'lock',
		hr: 'Trezor',
		en: 'Vault',
		emptyHr: 'Trezor je prazan.',
		emptyEn: 'The vault is empty.'
	}
];

export const adminNav: NavItem[] = [
	{
		path: '/admin',
		icon: 'grid',
		hr: 'Pregled',
		en: 'Overview',
		emptyHr: '',
		emptyEn: ''
	},
	{
		path: '/admin/users',
		icon: 'users',
		hr: 'Korisnici',
		en: 'Users',
		emptyHr: '',
		emptyEn: ''
	},
	{
		path: '/admin/jobs',
		icon: 'list',
		hr: 'Poslovi',
		en: 'Jobs',
		emptyHr: '',
		emptyEn: ''
	},
	{
		path: '/admin/storage',
		icon: 'db',
		hr: 'Pohrana',
		en: 'Storage',
		emptyHr: '',
		emptyEn: ''
	},
	{
		path: '/admin/settings',
		icon: 'cog',
		hr: 'Postavke',
		en: 'Settings',
		emptyHr: 'Postavke stižu u kasnijoj fazi.',
		emptyEn: 'Settings arrive in a later phase.'
	},
	{
		path: '/admin/audit',
		icon: 'shield',
		hr: 'Dnevnik aktivnosti',
		en: 'Activity log',
		emptyHr: 'Dnevnik aktivnosti stiže u kasnijoj fazi.',
		emptyEn: 'The activity log arrives in a later phase.'
	},
	{
		path: '/admin/health',
		icon: 'pulse',
		hr: 'Zdravlje',
		en: 'Health',
		emptyHr: '',
		emptyEn: ''
	}
];
