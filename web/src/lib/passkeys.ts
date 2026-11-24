import { ApiError } from './api.ts';
import { t } from './i18n.svelte.ts';

type Begin = {
	challengeId: string;
	options: { publicKey: PublicKeyCredentialCreationOptionsJSON };
};
type BeginLogin = {
	challengeId: string;
	options: { publicKey: PublicKeyCredentialRequestOptionsJSON };
};

async function post<T>(path: string, body: unknown): Promise<T> {
	const response = await fetch(path, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(body)
	});
	if (!response.ok) {
		const data = await response.json().catch(() => ({}));
		throw new ApiError(response.status, data.message ?? t('common.somethingWentWrong'), false);
	}
	return (response.status === 204 ? undefined : await response.json()) as T;
}

export async function registerPasskey(name: string, password: string) {
	const begun = await post<Begin>('/api/me/passkeys/begin', { password });
	const created = await navigator.credentials.create({
		publicKey: PublicKeyCredential.parseCreationOptionsFromJSON(begun.options.publicKey)
	});
	if (!created) throw new Error(t('passkeys.noneMade'));
	await post('/api/me/passkeys/finish', {
		challengeId: begun.challengeId,
		name,
		credential: (created as PublicKeyCredential).toJSON()
	});
}

export async function signInWithPasskey() {
	const begun = await post<BeginLogin>('/api/auth/passkey/begin', {});
	const found = await navigator.credentials.get({
		publicKey: PublicKeyCredential.parseRequestOptionsFromJSON(begun.options.publicKey)
	});
	if (!found) throw new Error(t('passkeys.noneChosen'));
	await post('/api/auth/passkey/finish', {
		challengeId: begun.challengeId,
		credential: (found as PublicKeyCredential).toJSON()
	});
}
