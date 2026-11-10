import { api, type CastMedia } from '#lib/api.ts';
import { absolute, tvSource } from './cast.ts';

/* The parts of Google's Cast sender that are used. It is loaded only when someone casts. */
type CastContext = {
	setOptions: (options: Record<string, unknown>) => void;
	requestSession: () => Promise<unknown>;
	getCurrentSession: () => CastSessionLike | null;
	endCurrentSession: (stopCasting: boolean) => void;
	addEventListener: (type: string, listener: (event: { sessionState?: string }) => void) => void;
};
type CastSessionLike = {
	loadMedia: (request: unknown) => Promise<unknown>;
	getCastDevice: () => { friendlyName: string };
};
type RemotePlayer = {
	isPaused: boolean;
	currentTime: number;
	duration: number;
	isMediaLoaded: boolean;
};
type RemotePlayerController = {
	playOrPause: () => void;
	seek: () => void;
	addEventListener: (type: string, listener: () => void) => void;
};
type CastFramework = {
	CastContext: { getInstance: () => CastContext };
	RemotePlayer: new () => RemotePlayer;
	RemotePlayerController: new (player: RemotePlayer) => RemotePlayerController;
	RemotePlayerEventType: { ANY_CHANGE: string };
	CastContextEventType: { SESSION_STATE_CHANGED: string };
	SessionState: { SESSION_ENDED: string };
};
type ChromeCast = {
	AutoJoinPolicy: { ORIGIN_SCOPED: string };
	media: {
		DEFAULT_MEDIA_RECEIVER_APP_ID: string;
		MediaInfo: new (url: string, type: string) => { metadata?: unknown; streamType?: string };
		PhotoMediaMetadata: new () => object;
		GenericMediaMetadata: new () => object;
		LoadRequest: new (info: unknown) => { autoplay?: boolean };
	};
};
type CastWindow = Window & {
	cast?: { framework?: CastFramework };
	chrome?: { cast?: ChromeCast };
	__onGCastApiAvailable?: (available: boolean) => void;
};

const SENDER = 'https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1';

export type Casting = {
	target: 'chromecast' | 'airplay';
	device: string;
	sessionId: string;
	token: string;
	current?: string;
	kind?: 'photo' | 'video';
	paused: boolean;
	position: number;
	duration: number;
};

let state = $state<Casting | null>(null);
// Not shown, only remembered: what the TV's session already has.
// eslint-disable-next-line svelte/prefer-svelte-reactivity
let sent = new Map<string, CastMedia>();
let controller: RemotePlayerController | undefined;
let player: RemotePlayer | undefined;

export function casting() {
	return state;
}

let loading: Promise<CastFramework> | undefined;

/** Loads Google's Cast sender once. A test, or a page that already has it, gives its own. */
function framework(): Promise<CastFramework> {
	const w = window as CastWindow;
	if (w.cast?.framework && w.chrome?.cast) return Promise.resolve(w.cast.framework);
	loading ??= new Promise((resolve, reject) => {
		w.__onGCastApiAvailable = (available) => {
			if (available && w.cast?.framework) resolve(w.cast.framework);
			else reject(new Error('cast is not available'));
		};
		const script = document.createElement('script');
		script.src = SENDER;
		script.onerror = () => reject(new Error('the cast sender did not load'));
		document.head.append(script);
	});
	loading.catch(() => (loading = undefined));
	return loading;
}

/** Adds an asset to the TV's session if it is not there yet, and says where the TV finds it. */
async function mediaOf(id: string): Promise<CastMedia> {
	const known = sent.get(id);
	if (known) return known;
	if (!state) throw new Error('not casting');
	const added = await api.addToCast(state.sessionId, [id]);
	for (const media of added.media) sent.set(media.id, media);
	const media = sent.get(id);
	if (!media) throw new Error('this cannot be shown on a TV');
	return media;
}

async function loadOnChromecast(media: CastMedia) {
	const w = window as CastWindow;
	const chrome = w.chrome?.cast;
	const session = w.cast?.framework?.CastContext.getInstance().getCurrentSession();
	if (!state || !chrome || !session) return;
	const source = tvSource(media, state.token);
	const info = new chrome.media.MediaInfo(absolute(location.origin, source.url), source.type);
	info.metadata =
		media.kind === 'video'
			? new chrome.media.GenericMediaMetadata()
			: new chrome.media.PhotoMediaMetadata();
	const request = new chrome.media.LoadRequest(info);
	request.autoplay = true;
	await session.loadMedia(request);
	state.current = media.id;
	state.kind = media.kind;
	state.paused = false;
	state.position = 0;
	state.duration = (media.durationMs ?? 0) / 1000;
}

/** Opens Chrome's device picker and shows this asset on the chosen Chromecast. */
export async function startChromecast(id: string) {
	const cf = await framework();
	const chrome = (window as CastWindow).chrome?.cast;
	if (!chrome) throw new Error('cast is not available');
	const context = cf.CastContext.getInstance();
	context.setOptions({
		receiverApplicationId: chrome.media.DEFAULT_MEDIA_RECEIVER_APP_ID,
		autoJoinPolicy: chrome.AutoJoinPolicy.ORIGIN_SCOPED
	});
	await context.requestSession();
	const session = context.getCurrentSession();
	if (!session) return;
	await begin('chromecast', session.getCastDevice().friendlyName, id);
	player = new cf.RemotePlayer();
	controller = new cf.RemotePlayerController(player);
	controller.addEventListener(cf.RemotePlayerEventType.ANY_CHANGE, () => {
		if (!state || !player) return;
		state.paused = player.isPaused;
		state.position = player.currentTime;
		if (player.duration) state.duration = player.duration;
	});
	context.addEventListener(cf.CastContextEventType.SESSION_STATE_CHANGED, (event) => {
		// Stopped from the TV, or from Chrome's own menu: the token goes too.
		if (event.sessionState === cf.SessionState.SESSION_ENDED) void stopCasting(false);
	});
	const media = await mediaOf(id);
	await loadOnChromecast(media);
}

async function begin(target: Casting['target'], device: string, id: string) {
	if (state) await stopCasting();
	const session = await api.startCast([id]);
	// eslint-disable-next-line svelte/prefer-svelte-reactivity -- as above
	sent = new Map(session.media.map((media) => [media.id, media]));
	state = {
		target,
		device,
		sessionId: session.id,
		token: session.token ?? '',
		// Already on its way to the TV, so following the screen does not send it twice.
		current: id,
		paused: false,
		position: 0,
		duration: 0
	};
}

/**
 * Sends a video to an Apple TV from Safari. The Apple TV fetches the video itself, without this
 * browser's cookie, so the video is switched to the TV's own address first.
 */
export async function startAirPlay(video: HTMLVideoElement, id: string) {
	await begin('airplay', 'AirPlay', id);
	const media = await mediaOf(id);
	if (!state) return;
	const source = tvSource(media, state.token);
	const at = video.currentTime;
	video.src = absolute(location.origin, source.url);
	video.currentTime = at;
	state.current = id;
	state.kind = media.kind;
	const target = video as HTMLVideoElement & {
		webkitShowPlaybackTargetPicker?: () => void;
	};
	video.addEventListener('webkitcurrentplaybacktargetiswirelesschanged', () => {
		const wireless = (video as unknown as { webkitCurrentPlaybackTargetIsWireless?: boolean })
			.webkitCurrentPlaybackTargetIsWireless;
		if (!wireless && state?.target === 'airplay') void stopCasting(false);
	});
	target.webkitShowPlaybackTargetPicker?.();
}

/** Called as the photo on the screen changes: the TV follows. */
export async function follow(id: string) {
	if (!state || state.target !== 'chromecast' || state.current === id) return;
	const media = await mediaOf(id);
	await loadOnChromecast(media);
}

export function playOrPause() {
	controller?.playOrPause();
	if (state) state.paused = !state.paused;
}

export function seekTo(seconds: number) {
	if (!player || !controller) return;
	player.currentTime = seconds;
	controller.seek();
	if (state) state.position = seconds;
}

/** Stops casting. The TV's token stops working at once, also if the TV kept the address. */
export async function stopCasting(endOnDevice = true) {
	const ending = state;
	state = null;
	// eslint-disable-next-line svelte/prefer-svelte-reactivity -- as above
	sent = new Map();
	controller = undefined;
	player = undefined;
	if (!ending) return;
	if (endOnDevice && ending.target === 'chromecast') {
		(window as CastWindow).cast?.framework?.CastContext.getInstance().endCurrentSession(true);
	}
	await api.stopCast(ending.sessionId).catch(() => undefined);
}
