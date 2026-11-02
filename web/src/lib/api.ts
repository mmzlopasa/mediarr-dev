import type { components } from './api/schema';

export type User = components['schemas']['User'];
export type Asset = components['schemas']['Asset'];
export type AssetList = components['schemas']['AssetList'];
export type AuthStatus = components['schemas']['AuthStatus'];
export type TotpSetup = components['schemas']['TotpSetup'];

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

async function request<T>(fetcher: Fetch, path: string, body?: unknown): Promise<T> {
	const response = await fetcher(path, {
		method: body === undefined ? 'GET' : 'POST',
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
	listUsers: () => request<User[]>(fetch, '/api/admin/users'),
	createUser: (body: { email: string; name: string; password: string; isAdmin: boolean }) =>
		request<User>(fetch, '/api/admin/users', body),
	listAssets: () => request<AssetList>(fetch, '/api/assets?limit=200')
};

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
