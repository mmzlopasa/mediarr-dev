import type Lenis from 'lenis';

/**
 * Motion for Mediarr: GSAP for what appears and what follows the scroll, Lenis for a smooth wheel.
 * Rules (docs/specs/pokret-gsap-lenis-reactbits.md): motion where something opens, appears or
 * counts, once; never on what is used all the time (the timeline as it scrolls, the film edge, the
 * viewer, arrows and the remote). Reduced motion turns it all off.
 */

type Gsap = typeof import('gsap').gsap;
type ScrollTriggerType = typeof import('gsap/ScrollTrigger').ScrollTrigger;
type SplitTextType = typeof import('gsap/SplitText').SplitText;
export type Kit = { gsap: Gsap; ScrollTrigger: ScrollTriggerType; SplitText: SplitTextType };

let kit: Promise<Kit> | undefined;
let lenis: Lenis | undefined;

export function reduced(): boolean {
	return (
		typeof window === 'undefined' || window.matchMedia('(prefers-reduced-motion: reduce)').matches
	);
}

/** GSAP with its scroll and text plugins, loaded once and only where motion is used. */
export function motionKit(): Promise<Kit> {
	kit ??= Promise.all([
		import('gsap'),
		import('gsap/ScrollTrigger'),
		import('gsap/SplitText')
	]).then(([core, scroll, split]) => {
		core.gsap.registerPlugin(scroll.ScrollTrigger, split.SplitText);
		if (lenis) lenis.on('scroll', scroll.ScrollTrigger.update);
		return { gsap: core.gsap, ScrollTrigger: scroll.ScrollTrigger, SplitText: split.SplitText };
	});
	return kit;
}

/**
 * A smooth wheel on a desktop. Touch keeps the phone's own scrolling, and anything marked
 * data-lenis-prevent (panels, menus, the viewer) scrolls on its own.
 */
export async function startSmoothScroll(): Promise<() => void> {
	if (reduced() || !window.matchMedia('(pointer: fine)').matches) return () => {};
	const { default: LenisClass } = await import('lenis');
	lenis = new LenisClass({ autoRaf: true, lerp: 0.12, smoothWheel: true, syncTouch: false });
	document.documentElement.classList.add('lenis');
	if (kit) void kit.then(({ ScrollTrigger }) => lenis?.on('scroll', ScrollTrigger.update));
	return () => {
		lenis?.destroy();
		lenis = undefined;
		document.documentElement.classList.remove('lenis');
	};
}

/** Scrolls the page; a jump (the film edge, a link to a part) goes at once. */
export function scrollPageTo(top: number, immediate = true) {
	if (lenis) lenis.scrollTo(top, { immediate, force: true });
	else window.scrollTo({ top, behavior: immediate ? 'instant' : 'smooth' });
}

/**
 * Moves the page by a distance without the reader noticing, as when a part above changes height.
 * A smooth scroll under way keeps going from the new place.
 */
export function shiftPage(delta: number) {
	if (!lenis) {
		window.scrollBy(0, delta);
		return;
	}
	const remaining = lenis.targetScroll - lenis.animatedScroll;
	const here = lenis.animatedScroll + delta;
	lenis.scrollTo(here, { immediate: true, force: true });
	if (Math.abs(remaining) > 0.5) lenis.scrollTo(here + remaining, { force: true });
}

/** Stops the smooth wheel while a layer (the viewer, a dialog) owns the scroll. */
export function holdScroll(held: boolean) {
	if (!lenis) return;
	if (held) lenis.stop();
	else lenis.start();
}
