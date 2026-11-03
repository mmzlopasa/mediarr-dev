import type { components } from './api/schema';

export type User = components['schemas']['User'];
export type Asset = components['schemas']['Asset'];
export type AssetList = components['schemas']['AssetList'];
export type AuthStatus = components['schemas']['AuthStatus'];
export type TotpSetup = components['schemas']['TotpSetup'];
export type AdminOverview = components['schemas']['AdminOverview'];
export type TimelineItem = components['schemas']['TimelineItem'];
export type TimelineBucket = components['schemas']['TimelineBucket'];
export type TimelineBuckets = components['schemas']['TimelineBuckets'];
export type AssetDetail = components['schemas']['AssetDetail'];
export type BulkAction = components['schemas']['BulkRequest']['action'];
export type Album = components['schemas']['Album'];
export type AlbumRules = components['schemas']['AlbumRules'];
export type AlbumMember = components['schemas']['AlbumMember'];
export type UserRef = components['schemas']['UserRef'];
export type Activity = components['schemas']['Activity'];
export type ShareLink = components['schemas']['ShareLink'];
export type ShareLinkCreate = components['schemas']['ShareLinkCreate'];
export type PublicLink = components['schemas']['PublicLink'];
export type Partners = components['schemas']['Partners'];
export type PartnerEntry = components['schemas']['PartnerEntry'];
export type MemberRole = AlbumMember['role'];
export type Tag = components['schemas']['Tag'];
export type Folder = components['schemas']['Folder'];
export type ExternalLibrary = components['schemas']['ExternalLibrary'];
export type Duplicates = components['schemas']['Duplicates'];
export type DuplicateGroup = components['schemas']['DuplicateGroup'];
export type MapPoints = components['schemas']['MapPoints'];
export type Memory = components['schemas']['Memory'];
export type StoryExport = components['schemas']['StoryExport'];
export type SearchResult = components['schemas']['SearchResult'];
export type Person = components['schemas']['Person'];
export type PeopleList = components['schemas']['PeopleList'];
export type AnalysisProgress = components['schemas']['AnalysisProgress'];
export type Trip = components['schemas']['Trip'];
export type MapStyle = components['schemas']['MapStyle'];
export type VaultStatus = components['schemas']['VaultStatus'];

export class ApiError extends Error {
	status: number;
	totpRequired: boolean;

	constructor(status: number, message: string, totpRequired = false) {
		super(message);
		this.status = status;
		this.totpRequired = totpRequired;
	}
}

type Fetch = typeof fetch;

async function request<T>(
	fetcher: Fetch,
	path: string,
	body?: unknown,
	method?: 'PUT' | 'PATCH' | 'DELETE'
): Promise<T> {
	const response = await fetcher(path, {
		method: method ?? (body === undefined ? 'GET' : 'POST'),
		headers: body === undefined ? undefined : { 'Content-Type': 'application/json' },
		body: body === undefined ? undefined : JSON.stringify(body)
	});
	if (response.status === 204) return undefined as T;
	const data = await response.json().catch(() => ({}));
	if (!response.ok) {
		throw new ApiError(
			response.status,
			data.message ?? 'Something went wrong',
			data.totpRequired ?? false
		);
	}
	return data as T;
}

export const api = {
	status: (fetcher: Fetch = fetch) => request<AuthStatus>(fetcher, '/api/auth/status'),
	setup: (body: { email: string; name: string; password: string }) =>
		request<User>(fetch, '/api/auth/setup', body),
	login: (body: { email: string; password: string; totpCode?: string }) =>
		request<User>(fetch, '/api/auth/login', body),
	logout: () => request<void>(fetch, '/api/auth/logout', {}),
	changePassword: (body: { currentPassword: string; newPassword: string }) =>
		request<void>(fetch, '/api/me/password', body),
	setupTotp: () => request<TotpSetup>(fetch, '/api/me/totp/setup', {}),
	enableTotp: (code: string) => request<void>(fetch, '/api/me/totp/enable', { code }),
	disableTotp: (password: string) => request<void>(fetch, '/api/me/totp/disable', { password }),
	adminOverview: () => request<AdminOverview>(fetch, '/api/admin/overview'),
	listUsers: () => request<User[]>(fetch, '/api/admin/users'),
	createUser: (body: { email: string; name: string; password: string; isAdmin: boolean }) =>
		request<User>(fetch, '/api/admin/users', body),
	listProblems: () => request<AssetList>(fetch, '/api/assets?limit=200&status=failed'),
	timelineBuckets: () => request<TimelineBuckets>(fetch, '/api/timeline/buckets'),
	timelineBucket: (month: string) =>
		request<TimelineBucket>(fetch, `/api/timeline/buckets/${month}`),
	asset: (id: string) => request<AssetDetail>(fetch, `/api/assets/${id}`),
	bulk: (ids: string[], action: BulkAction) =>
		request<{ changed: number }>(fetch, '/api/assets/bulk', { ids, action }),

	directory: () => request<UserRef[]>(fetch, '/api/users/directory'),
	albums: (sort: 'updated' | 'title' | 'date' = 'updated') =>
		request<Album[]>(fetch, `/api/albums?sort=${sort}`),
	cameras: () => request<string[]>(fetch, '/api/albums/cameras'),
	createAlbum: (body: { title: string; description?: string; rules?: AlbumRules }) =>
		request<Album>(fetch, '/api/albums', body),
	album: (id: string) => request<Album>(fetch, `/api/albums/${id}`),
	updateAlbum: (
		id: string,
		body: {
			title?: string;
			description?: string;
			order?: Album['order'];
			coverAssetId?: string;
			rules?: AlbumRules;
		}
	) => request<Album>(fetch, `/api/albums/${id}`, body, 'PATCH'),
	deleteAlbum: (id: string) => request<void>(fetch, `/api/albums/${id}`, undefined, 'DELETE'),
	addToAlbum: (id: string, ids: string[]) =>
		request<{ changed: number }>(fetch, `/api/albums/${id}/assets`, { ids }),
	removeFromAlbum: (id: string, ids: string[]) =>
		request<{ changed: number }>(fetch, `/api/albums/${id}/assets/remove`, { ids }),
	setMember: (id: string, userId: string, role: MemberRole) =>
		request<void>(fetch, `/api/albums/${id}/members/${userId}`, { role }, 'PUT'),
	removeMember: (id: string, userId: string) =>
		request<void>(fetch, `/api/albums/${id}/members/${userId}`, undefined, 'DELETE'),
	activity: (id: string, assetId?: string) =>
		request<Activity>(fetch, `/api/albums/${id}/comments${assetId ? `?assetId=${assetId}` : ''}`),
	addComment: (id: string, body: string, assetId?: string) =>
		request<void>(fetch, `/api/albums/${id}/comments`, { body, assetId }),
	deleteComment: (id: string, commentId: string) =>
		request<void>(fetch, `/api/albums/${id}/comments/${commentId}`, undefined, 'DELETE'),
	setHeart: (id: string, assetId: string, on: boolean) =>
		request<void>(
			fetch,
			`/api/albums/${id}/assets/${assetId}/heart`,
			undefined,
			on ? 'PUT' : 'DELETE'
		),
	links: (id: string) => request<ShareLink[]>(fetch, `/api/albums/${id}/links`),
	createLink: (id: string, body: ShareLinkCreate) =>
		request<ShareLink>(fetch, `/api/albums/${id}/links`, body),
	deleteLink: (id: string, linkId: string) =>
		request<void>(fetch, `/api/albums/${id}/links/${linkId}`, undefined, 'DELETE'),
	partners: () => request<Partners>(fetch, '/api/partners'),
	setPartner: (userId: string, since?: string) =>
		request<void>(fetch, `/api/partners/${userId}`, { since }, 'PUT'),
	removePartner: (userId: string) =>
		request<void>(fetch, `/api/partners/${userId}`, undefined, 'DELETE'),
	setPartnerTimeline: (userId: string, show: boolean) =>
		request<void>(fetch, `/api/partners/${userId}/timeline`, { show }, 'PUT'),
	mapPoints: (from?: string, to?: string) => {
		const query = new URLSearchParams();
		if (from) query.set('from', from);
		if (to) query.set('to', to);
		return request<MapPoints>(fetch, `/api/map/points?${query}`);
	},
	mapTrips: () => request<Trip[]>(fetch, '/api/map/trips'),
	mapStyle: () => request<MapStyle>(fetch, '/api/map/style'),
	setMapStyle: (body: MapStyle) => request<MapStyle>(fetch, '/api/map/style', body, 'PUT'),
	search: (query: string) =>
		request<SearchResult>(fetch, `/api/search?q=${encodeURIComponent(query)}`),
	people: () => request<PeopleList>(fetch, '/api/people'),
	updatePerson: (id: string, body: { name?: string; hidden?: boolean }) =>
		request<void>(fetch, `/api/people/${id}`, body, 'PATCH'),
	mergePeople: (id: string, ids: string[]) =>
		request<void>(fetch, `/api/people/${id}/merge`, { ids }),
	analysisProgress: () => request<AnalysisProgress>(fetch, '/api/admin/analysis'),
	memories: (date: string) => request<Memory[]>(fetch, `/api/memories?date=${date}`),
	createStory: (title: string, ids: string[]) =>
		request<StoryExport>(fetch, '/api/stories', { title, ids }),
	story: (id: string) => request<StoryExport>(fetch, `/api/stories/${id}`),
	emptyTrash: () => request<{ changed: number }>(fetch, '/api/trash/empty', {}),
	vaultStatus: () => request<VaultStatus>(fetch, '/api/vault/status'),
	setVaultPin: (pin: string, currentPin?: string) =>
		request<void>(fetch, '/api/vault/pin', { pin, currentPin }),
	unlockVault: (pin: string) => request<{ token: string }>(fetch, '/api/vault/unlock', { pin }),
	lockVault: () => request<void>(fetch, '/api/vault/lock', {}),
	tags: () => request<Tag[]>(fetch, '/api/tags'),
	folder: (path: string) => request<Folder>(fetch, `/api/folders?path=${encodeURIComponent(path)}`),
	externalLibrary: () => request<ExternalLibrary>(fetch, '/api/admin/external'),
	setExternalOwner: (ownerId: string) =>
		request<ExternalLibrary>(fetch, '/api/admin/external', { ownerId }, 'PUT'),
	scanExternal: () => request<void>(fetch, '/api/admin/external/scan', {}),
	duplicates: () => request<Duplicates>(fetch, '/api/duplicates'),
	dismissDuplicates: (ids: string[]) => request<void>(fetch, '/api/duplicates/dismiss', { ids }),
	setStackMain: (id: string) =>
		request<void>(fetch, `/api/assets/${id}/stack/main`, undefined, 'PUT'),
	dissolveStack: (id: string) =>
		request<void>(fetch, `/api/assets/${id}/stack`, undefined, 'DELETE'),
	deleteTag: (id: string) => request<void>(fetch, `/api/tags/${id}`, undefined, 'DELETE'),
	changeTag: (ids: string[], name: string, remove = false) =>
		request<{ changed: number }>(fetch, '/api/assets/tags', { ids, name, remove }),
	publicLink: (token: string) => request<PublicLink>(fetch, `/api/public/${token}`),
	unlockLink: (token: string, password: string) =>
		request<void>(fetch, `/api/public/${token}/unlock`, { password })
};

/** Where a timeline reads its months from: the library, an album, a partner or a public link. */
export type TimelineSource = {
	buckets: () => Promise<TimelineBuckets>;
	bucket: (month: string) => Promise<TimelineBucket>;
};

function sourceAt(path: string): TimelineSource {
	return {
		buckets: () => request<TimelineBuckets>(fetch, `${path}/buckets`),
		bucket: (month) => request<TimelineBucket>(fetch, `${path}/buckets/${month}`)
	};
}

export const librarySource = sourceAt('/api/timeline');
export const albumSource = (id: string) => sourceAt(`/api/albums/${id}`);
export const partnerSource = (id: string) => sourceAt(`/api/partners/${id}`);
export const publicSource = (token: string) => sourceAt(`/api/public/${token}`);
export const tagSource = (id: string) => sourceAt(`/api/tags/${id}`);
export const personSource = (id: string) => sourceAt(`/api/people/${id}`);
export const collectionBase = (scope: 'archive' | 'trash' | 'vault') => `/api/collections/${scope}`;
export const collectionSource = (scope: 'archive' | 'trash' | 'vault') =>
	sourceAt(collectionBase(scope));

export function initialsOf(name: string) {
	const parts = name.trim().split(/\s+/);
	const letters = parts.length > 1 ? parts[0][0] + parts[parts.length - 1][0] : name.slice(0, 2);
	return letters.toUpperCase();
}

export function formatBytes(bytes: number) {
	const units = ['B', 'KB', 'MB', 'GB', 'TB'];
	let value = bytes;
	let unit = 0;
	while (value >= 1024 && unit < units.length - 1) {
		value /= 1024;
		unit += 1;
	}
	return `${unit === 0 ? value : value.toFixed(1)} ${units[unit]}`;
}
