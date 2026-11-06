import { motionKit, reduced } from './motion.ts';

/*
 * The moving pieces. revealTitle, revealGrid, magnet, countUp and pulse follow React Bits
 * (SplitText, AnimatedContent, Magnet, CountUp, PulseHeart; https://github.com/DavidHDev/react-bits,
 * Copyright (c) 2026 David Haz, MIT + Commons Clause, used as part of this application only; see
 * web/THIRD_PARTY_NOTICES.md), rewritten for Svelte on GSAP.
 */

const EASE_OUT = 'expo.out';

/** A heading rises out of its own line, letter by letter, once. Screen readers get the text whole. */
export function revealTitle(node: HTMLElement) {
	if (reduced()) return;
	let undo: (() => void) | undefined;
	let gone = false;
	node.style.visibility = 'hidden';
	// The title never waits long for its motion: if the code is not here at once, it just shows.
	const late = new Promise<'late'>((done) => setTimeout(() => done('late'), 400));
	void (async () => {
		const ready = await Promise.race([
			Promise.all([motionKit(), document.fonts?.ready]).then(([kit]) => kit),
			late
		]);
		if (gone) return;
		if (ready === 'late') {
			node.style.visibility = '';
			return;
		}
		const { gsap, SplitText } = ready;
		const split = SplitText.create(node, {
			type: 'words,chars',
			mask: 'words',
			aria: 'auto',
			wordsClass: 'mo-word'
		});
		node.style.visibility = '';
		const tween = gsap.from(split.chars, {
			yPercent: 110,
			duration: 0.9,
			ease: EASE_OUT,
			stagger: { each: 0.018, from: 'start' },
			onComplete: () => split.revert()
		});
		undo = () => {
			tween.kill();
			split.revert();
		};
	})();
	return {
		destroy() {
			gone = true;
			node.style.visibility = '';
			undo?.();
		}
	};
}

/**
 * Cards come in as a wave as they reach the screen (fade and 14 px), only the first time. Cards
 * that arrive later (more loaded, a refresh) join the wave when they come into view.
 */
export function revealGrid(node: HTMLElement) {
	if (reduced()) return;
	const seen = new WeakSet<Element>();
	let gone = false;
	let observer: MutationObserver | undefined;
	const triggers: { kill(): void }[] = [];
	node.classList.add('mo-grid');
	// If the motion code never arrives, the cards must not stay hidden.
	const fallback = setTimeout(() => node.classList.add('mo-ready'), 2500);

	void motionKit().then(({ gsap, ScrollTrigger }) => {
		if (gone) return;
		const take = () => {
			const fresh = [...node.children].filter((child) => !seen.has(child));
			if (!fresh.length) return;
			fresh.forEach((child) => seen.add(child));
			gsap.set(fresh, { autoAlpha: 0, y: 14 });
			triggers.push(
				...ScrollTrigger.batch(fresh, {
					once: true,
					start: 'top 96%',
					onEnter: (batch) =>
						gsap.to(batch, {
							autoAlpha: 1,
							y: 0,
							duration: 0.6,
							ease: 'power3.out',
							stagger: 0.05,
							overwrite: true,
							clearProps: 'transform,opacity,visibility'
						})
				})
			);
		};
		take();
		clearTimeout(fallback);
		node.classList.add('mo-ready');
		observer = new MutationObserver(take);
		observer.observe(node, { childList: true });
	});

	return {
		destroy() {
			gone = true;
			clearTimeout(fallback);
			observer?.disconnect();
			triggers.forEach((trigger) => trigger.kill());
		}
	};
}

/** A picture moves slower than the page as it scrolls by, with a slight zoom. */
export function parallax(node: HTMLElement, depth = 18) {
	if (reduced()) return;
	let undo: (() => void) | undefined;
	let gone = false;
	void motionKit().then(({ gsap }) => {
		if (gone) return;
		const tween = gsap.fromTo(
			node,
			{ yPercent: -depth / 2, scale: 1.08 },
			{
				yPercent: depth / 2,
				scale: 1,
				ease: 'none',
				scrollTrigger: {
					trigger: node.parentElement ?? node,
					start: 'top bottom',
					end: 'bottom top',
					scrub: true
				}
			}
		);
		undo = () => {
			tween.scrollTrigger?.kill();
			tween.kill();
		};
	});
	return {
		destroy() {
			gone = true;
			undo?.();
		}
	};
}

/**
 * The control leans toward the pointer when it comes near, on a spring, and settles back when it
 * goes. Only with a mouse: on touch there is nothing to lean toward.
 */
export function magnet(
	node: HTMLElement,
	options: { reach?: number; pull?: number; most?: number; off?: boolean } = {}
) {
	if (options.off || reduced() || !window.matchMedia('(hover: hover) and (pointer: fine)').matches)
		return;
	const reach = options.reach ?? 70;
	const pull = options.pull ?? 4;
	const most = options.most ?? 8;
	const stiffness = 170;
	const damping = 16;
	const at = { x: 0, y: 0 };
	const speed = { x: 0, y: 0 };
	let target = { x: 0, y: 0 };
	let frame = 0;
	let last = 0;

	const smooth = (edge0: number, edge1: number, value: number) => {
		const t = Math.min(1, Math.max(0, (value - edge0) / (edge1 - edge0)));
		return t * t * (3 - 2 * t);
	};

	const tick = (now: number) => {
		frame = 0;
		const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60;
		last = now;
		let resting = true;
		for (const key of ['x', 'y'] as const) {
			const force = stiffness * (target[key] - at[key]) - damping * speed[key];
			speed[key] += force * dt;
			at[key] += speed[key] * dt;
			if (Math.abs(target[key] - at[key]) > 0.05 || Math.abs(speed[key]) > 0.05) resting = false;
		}
		if (resting) {
			at.x = target.x;
			at.y = target.y;
			last = 0;
		}
		node.style.translate = `${at.x.toFixed(2)}px ${at.y.toFixed(2)}px`;
		if (!resting) frame = requestAnimationFrame(tick);
	};
	const wake = () => {
		if (!frame) frame = requestAnimationFrame(tick);
	};

	const move = (event: PointerEvent) => {
		if (event.pointerType === 'touch') return;
		const box = node.getBoundingClientRect();
		const dx = event.clientX - (box.left + box.width / 2);
		const dy = event.clientY - (box.top + box.height / 2);
		const outside = Math.hypot(
			Math.max(0, Math.abs(dx) - box.width / 2),
			Math.max(0, Math.abs(dy) - box.height / 2)
		);
		let next = { x: 0, y: 0 };
		if (outside <= reach) {
			const strength = 1 - smooth(reach * 0.5, reach, outside);
			next = { x: (dx / pull) * strength, y: (dy / pull) * strength };
			const length = Math.hypot(next.x, next.y);
			if (length > most) next = { x: (next.x * most) / length, y: (next.y * most) / length };
		}
		if (next.x !== target.x || next.y !== target.y) {
			target = next;
			wake();
		}
	};
	const leave = () => {
		target = { x: 0, y: 0 };
		wake();
	};

	window.addEventListener('pointermove', move, { passive: true });
	document.documentElement.addEventListener('pointerleave', leave);
	return {
		destroy() {
			cancelAnimationFrame(frame);
			window.removeEventListener('pointermove', move);
			document.documentElement.removeEventListener('pointerleave', leave);
			node.style.translate = '';
		}
	};
}

/**
 * A number counts up to its value when it comes into view. The real value is in the page from the
 * start (for screen readers and if motion is off); only what is drawn counts.
 */
export function countUp(
	node: HTMLElement,
	options: { value: number; format?: (value: number) => string }
) {
	const format = options.format ?? ((value: number) => Math.round(value).toLocaleString());
	node.textContent = format(options.value);
	if (reduced() || options.value === 0) return { update: (next: typeof options) => show(next) };
	let done = false;
	let gone = false;
	let killer: (() => void) | undefined;
	function show(next: typeof options) {
		node.textContent = (next.format ?? format)(next.value);
	}
	const label = node.textContent;
	node.setAttribute('aria-label', label);
	void motionKit().then(({ gsap, ScrollTrigger }) => {
		if (gone) return;
		const state = { value: 0 };
		const tween = gsap.to(state, {
			value: options.value,
			duration: 1.4,
			ease: 'power3.out',
			paused: true,
			onUpdate: () => {
				node.textContent = format(state.value);
			},
			onComplete: () => {
				done = true;
				node.removeAttribute('aria-label');
				node.textContent = format(options.value);
			}
		});
		node.textContent = format(0);
		const trigger = ScrollTrigger.create({
			trigger: node,
			start: 'top 95%',
			once: true,
			onEnter: () => tween.play()
		});
		killer = () => {
			trigger.kill();
			tween.kill();
		};
	});
	return {
		update(next: typeof options) {
			if (done || gone) show(next);
			options = next;
		},
		destroy() {
			gone = true;
			killer?.();
		}
	};
}

/**
 * The heart shrinks to a dot, takes its new state, and springs back past its size: the moment a
 * picture becomes a favourite.
 */
export function pulse(node: Element | null | undefined) {
	if (!node || reduced()) return;
	const target = node as HTMLElement;
	const duration = 560;
	const dot = 0.3;
	const overshoot = 1.7;
	const turn = 0.4;
	const back = (k: number) => {
		const u = k - 1;
		return 1 + (overshoot + 1) * u ** 3 + overshoot * u ** 2;
	};
	const swell = (t: number) =>
		t <= 0 ? 0 : t < turn ? 1 - (1 - t / turn) ** 3 : 1 - back((t - turn) / (1 - turn));
	const start = performance.now();
	const tick = (now: number) => {
		const t = Math.min(1, (now - start) / duration);
		target.style.scale = String(1 - (1 - dot) * swell(t));
		if (t < 1) requestAnimationFrame(tick);
		else target.style.scale = '';
	};
	requestAnimationFrame(tick);
}

/**
 * A picture drifts and grows a little for as long as it is shown, the slow pan of a documentary.
 * Each picture moves a different way, so a story does not feel like one picture zooming.
 */
export function kenBurns(node: HTMLElement, options: { seconds: number; turn?: number }) {
	if (reduced()) return;
	let undo: (() => void) | undefined;
	let gone = false;
	const turn = options.turn ?? 0;
	const ways = [
		{ x: -2, y: -1.5 },
		{ x: 2, y: -1 },
		{ x: -1.5, y: 1.5 },
		{ x: 1.5, y: 1 }
	];
	const way = ways[Math.abs(turn) % ways.length];
	void motionKit().then(({ gsap }) => {
		if (gone) return;
		const tween = gsap.fromTo(
			node,
			{ scale: 1.02, xPercent: 0, yPercent: 0 },
			{
				scale: 1.1,
				xPercent: way.x,
				yPercent: way.y,
				duration: options.seconds + 1,
				ease: 'none'
			}
		);
		undo = () => tween.kill();
	});
	return {
		destroy() {
			gone = true;
			undo?.();
		}
	};
}
