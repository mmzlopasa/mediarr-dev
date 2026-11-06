import { lang } from '#lib/i18n.svelte.ts';

export type Agent = { program: string; system: string; phone: boolean };

const PROGRAMS: [RegExp, string][] = [
	[/HeadlessChrome/, 'Headless Chrome'],
	[/Edg\//, 'Edge'],
	[/OPR\/|Opera/, 'Opera'],
	[/SamsungBrowser/, 'Samsung Internet'],
	[/Firefox\//, 'Firefox'],
	[/Chrome\/|CriOS/, 'Chrome'],
	[/Version\/[\d.]+.*Safari/, 'Safari'],
	[/^Dart\//, 'Mediarr app'],
	[/^curl\//, 'curl']
];

const SYSTEMS: [RegExp, string][] = [
	[/iPhone/, 'iPhone'],
	[/iPad/, 'iPad'],
	[/Android/, 'Android'],
	[/Windows/, 'Windows'],
	[/Mac OS X|Macintosh/, 'macOS'],
	[/CrOS/, 'ChromeOS'],
	[/Linux|X11/, 'Linux']
];

/** A browser's user agent in words a person knows: "Chrome on Windows". */
export function describeAgent(userAgent: string): Agent {
	const program = PROGRAMS.find(([pattern]) => pattern.test(userAgent))?.[1] ?? '';
	const system = SYSTEMS.find(([pattern]) => pattern.test(userAgent))?.[1] ?? '';
	return {
		program,
		system,
		phone: /iPhone|Android.*Mobile|Mobile Safari|^Dart\//.test(userAgent)
	};
}

/** How long ago, in the words of the chosen language: "3 hours ago". */
export function since(at: Date, now = new Date()): string {
	const seconds = Math.round((at.getTime() - now.getTime()) / 1000);
	const format = new Intl.RelativeTimeFormat(lang() === 'hr' ? 'hr' : 'en', { numeric: 'auto' });
	const steps: [Intl.RelativeTimeFormatUnit, number][] = [
		['second', 60],
		['minute', 60],
		['hour', 24],
		['day', 7],
		['week', 4.35],
		['month', 12],
		['year', Infinity]
	];
	let value = seconds;
	for (const [unit, size] of steps) {
		if (Math.abs(value) < size) return format.format(Math.round(value), unit);
		value /= size;
	}
	return format.format(Math.round(value), 'year');
}
