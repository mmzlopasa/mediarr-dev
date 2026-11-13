// Overlays opened over one another: the photo viewer, a slideshow over it, a menu in it, a dialog.
// Keys go only to the one on top, so Esc closes one thing and arrows step only what is in front.

const stack: symbol[] = [];

/** A modal <dialog> is always drawn over everything else, so it is on top while it is open. */
function modalDialogOpen(): boolean {
	if (typeof document === 'undefined') return false;
	try {
		return document.querySelector('dialog:modal') !== null;
	} catch {
		// A browser without :modal still knows which dialogs are open.
		return document.querySelector('dialog[open]') !== null;
	}
}

export type Layer = {
	/** Whether nothing was opened over this one. */
	isTop: () => boolean;
	close: () => void;
};

/** Puts an overlay on top; close it when it goes. */
export function openLayer(): Layer {
	const token = Symbol('layer');
	stack.push(token);
	return {
		isTop: () => stack[stack.length - 1] === token && !modalDialogOpen(),
		close: () => {
			const index = stack.indexOf(token);
			if (index >= 0) stack.splice(index, 1);
		}
	};
}

/** Whether any overlay is open over the page. */
export function anyLayerOpen(): boolean {
	return stack.length > 0 || modalDialogOpen();
}

const FOCUSABLE =
	'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),video[controls],[tabindex]:not([tabindex="-1"])';

function focusables(node: HTMLElement): HTMLElement[] {
	return [...node.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
		(element) => !element.closest('[inert]') && element.getClientRects().length > 0
	);
}

/**
 * Keeps keyboard focus inside a modal overlay while it is on top: Tab goes round its own controls,
 * and focus that wanders behind it is brought back.
 */
export function trapFocus(node: HTMLElement, layer: Layer) {
	function keydown(event: KeyboardEvent) {
		if (event.key !== 'Tab' || !layer.isTop()) return;
		const inside = focusables(node);
		if (inside.length === 0) {
			event.preventDefault();
			node.focus();
			return;
		}
		const first = inside[0];
		const last = inside[inside.length - 1];
		const active = document.activeElement;
		if (event.shiftKey && (active === first || active === node || !node.contains(active))) {
			event.preventDefault();
			last.focus();
		} else if (!event.shiftKey && (active === last || !node.contains(active))) {
			event.preventDefault();
			first.focus();
		}
	}

	function focusin(event: FocusEvent) {
		if (!layer.isTop()) return;
		const target = event.target as Node | null;
		if (target && !node.contains(target)) node.focus();
	}

	document.addEventListener('keydown', keydown);
	document.addEventListener('focusin', focusin);
	return () => {
		document.removeEventListener('keydown', keydown);
		document.removeEventListener('focusin', focusin);
	};
}

/** For a menu or panel while it is open: it is on top, and Esc closes it and nothing under it. */
export function escapeLayer(close: () => void) {
	const layer = openLayer();
	const key = (event: KeyboardEvent) => {
		if (event.key !== 'Escape' || !layer.isTop()) return;
		event.preventDefault();
		close();
	};
	window.addEventListener('keydown', key);
	return () => {
		window.removeEventListener('keydown', key);
		layer.close();
	};
}
