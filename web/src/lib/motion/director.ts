import { revealGrid, revealTitle } from './actions.ts';
import { motionKit, reduced } from './motion.ts';

/** Grids whose cards come in as a wave. The timeline is not one of them: it scrolls all day. */
const GRIDS = '.alb-grid, .folder-grid';
const TITLES = '.ph h1';

type Handle = { node: Element; destroy?: () => void };

/**
 * Watches the page for titles and card grids as they appear (most arrive after their data loads)
 * and gives them their motion, so every page gets it without each one asking.
 */
export function directMotion(main: HTMLElement) {
	if (reduced()) return () => {};
	void motionKit();
	const handles: Handle[] = [];
	const done = new WeakSet<Element>();

	const give = (node: Element, action: (node: HTMLElement) => { destroy(): void } | void) => {
		if (done.has(node) || !(node instanceof HTMLElement)) return;
		done.add(node);
		handles.push({ node, destroy: action(node)?.destroy });
	};
	const look = (root: Element) => {
		if (root.matches(TITLES)) give(root, revealTitle);
		if (root.matches(GRIDS) && !root.closest('[aria-hidden="true"]')) give(root, revealGrid);
		for (const title of root.querySelectorAll(TITLES)) give(title, revealTitle);
		for (const grid of root.querySelectorAll(GRIDS)) {
			if (!grid.closest('[aria-hidden="true"]')) give(grid, revealGrid);
		}
	};
	const sweep = () => {
		for (let i = handles.length - 1; i >= 0; i--) {
			if (!handles[i].node.isConnected) {
				handles[i].destroy?.();
				handles.splice(i, 1);
			}
		}
	};

	look(main);
	const observer = new MutationObserver((records) => {
		for (const record of records) {
			for (const added of record.addedNodes) {
				if (added instanceof Element && !added.closest('.tl, .viewer')) look(added);
			}
			if (record.removedNodes.length) sweep();
		}
	});
	observer.observe(main, { childList: true, subtree: true });
	return () => {
		observer.disconnect();
		handles.forEach((handle) => handle.destroy?.());
	};
}
