export const DOT_GRID_DEFAULTS: Record<string, unknown>;
export function startDotGrid(
	canvas: HTMLCanvasElement,
	settings: { current: Record<string, unknown> }
): { destroy(): void; refresh(): void; rebuild(): void };
