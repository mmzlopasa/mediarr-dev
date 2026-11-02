// Reference pages: markup copied from the owner's ScyHost PHP templates (shell_open, title_row,
// card, stat_card, pager, login.php), with Mediarr text, styled only by the unmodified dash.css.
// Comparing them to the Svelte pages proves that the design was carried over identically.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { icons, type IconName } from '../../src/lib/design/icons';
import { adminNav, appNav, type NavItem } from '../../src/lib/nav';

const logoSvelte = readFileSync(
	join(import.meta.dirname, '../../src/lib/design/components/Logo.svelte'),
	'utf8'
);
const logoSvg = /<svg class="logo-svg"[\s\S]*?<\/svg>/.exec(logoSvelte)![0];

const ico = (name: IconName, size = 18) =>
	`<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name]}</svg>`;

const logo = (tag = '') =>
	`<a class="logo" href="/">${logoSvg}${tag ? `<span class="logo-tag">${tag}</span>` : ''}</a>`;

const langMenu = `<details class="langdd "><summary aria-label="Language">HR<i aria-hidden="true"></i></summary><div class="langdd-m" role="menu"></div></details>`;
const themeBtn = `<button type="button" class="icon-btn" data-theme-btn aria-label="t"><span class="i-sun">${ico('sun')}</span><span class="i-moon">${ico('moon')}</span></button>`;

const document = (theme: string, bodyClass: string, body: string) =>
	`<!DOCTYPE html><html lang="hr" data-theme="${theme}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><link rel="stylesheet" href="/css/dash.css"><style>.logo{text-decoration:none}.logo-svg{flex:none}.logo-word,.logo-dot{fill:var(--gold)}html[data-theme=light] .logo-word{fill:var(--ink)}html[data-theme=light] .logo-dot{fill:var(--gold-3)}@media(max-width:900px){.in,.as-in:not(.code-in){font-size:16px}}</style></head><body class="${bodyClass}"><div class="sky" aria-hidden="true"></div>${body}</body></html>`;

function shell(
	theme: string,
	nav: NavItem[],
	active: string,
	tag: string,
	role: string,
	footLabel: string,
	foot: [IconName, string][],
	main: string
) {
	const items = nav
		.map(
			(item) =>
				`<a href="#" class="nav-i${item.path === active ? ' on' : ''}"><span class="ic">${ico(item.icon)}</span><span>${item.hr}</span></a>`
		)
		.join('');
	return document(
		theme,
		'app',
		`<a class="skip" href="#main">Preskoči na sadržaj</a><div class="layout"><aside class="side glass" id="side"><div class="side-top">${logo(tag)}<button class="icon-btn side-x" type="button">✕</button></div><nav class="nav">${items}</nav><div class="side-foot">${foot.map(([icon, label]) => `<a class="nav-i" href="#"><span class="ic">${ico(icon)}</span><span>${label}</span></a>`).join('')}</div></aside><div class="scrim"></div>` +
			`<div class="main-col"><header class="topbar"><button class="icon-btn menu-btn" type="button">${ico('menu')}</button><form class="gs" role="search"><label class="sr" for="gs-q">Traži</label>${ico('search', 16)}<input id="gs-q" class="in" name="q" type="search" placeholder="Traži fotke, osobe, mjesta…" autocomplete="off"></form><div class="top-r">${langMenu}${themeBtn}<div class="me"><span class="av" aria-hidden="true">DK</span><span class="me-t"><b>Demo korisnik</b><small>${role}</small></span></div><form class="inl"><button class="icon-btn">${ico('out')}</button></form></div></header>` +
			`<main id="main" class="main" tabindex="-1">${main}</main><footer class="foot">© ${new Date().getFullYear()} Mediarr · ${footLabel}</footer></div></div>`
	);
}

const titleRow = (title: string, sub = '') =>
	`<div class="ph"><div><h1>${title}</h1>${sub ? `<p>${sub}</p>` : ''}</div></div>`;
const emptyState = (icon: IconName, text: string, cta = '') =>
	`<div class="empty"><span class="ic lg">${ico(icon, 26)}</span><p>${text}</p>${cta}</div>`;
const card = (title: string, body: string) =>
	`<section class="card glass"><header class="card-h"><h2>${title}</h2></header><div class="card-b">${body}</div></section>`;
const bar = (pct: number) =>
	`<div class="bar" role="progressbar"><i class="${pct > 90 ? 'bad' : pct > 75 ? 'warn' : ''}" style="width:${pct}%"></i></div>`;
const stat = (label: string, value: string, sub = '', pct?: number) =>
	`<div class="stat glass"><span class="stat-l">${label}</span><b class="stat-v">${value}</b>${sub ? `<span class="stat-s">${sub}</span>` : ''}${pct === undefined ? '' : bar(pct)}</div>`;
const kv = (key: string, value: string) =>
	`<div class="kv"><span>${key}</span><b>${value}</b></div>`;
const alert = (kind: string, text: string) =>
	`<div class="alert ${kind}">${ico(kind === 'ok' ? 'check' : 'warn')}<span>${text}</span></div>`;
const badge = (text: string, kind = 'mute') => `<span class="badge ${kind}">${text}</span>`;

export function appPage(theme: string) {
	const item = appNav[0];
	return shell(
		theme,
		appNav,
		'/',
		'',
		'Korisnik',
		'Fotografije',
		[
			['user', 'Račun'],
			['shield', 'Administracija']
		],
		`<div class="ph"><div><h1>${item.hr}</h1></div><div class="ph-a"><button class="btn gold sm">${ico('upload', 14)} Upload</button><input class="sr" type="file" multiple tabindex="-1"></div></div>` +
			`<section class="card glass"><div class="card-b">${emptyState(item.icon, item.emptyHr)}</div></section>`
	);
}

export function adminPage(theme: string) {
	return shell(
		theme,
		adminNav,
		'/admin',
		'ADMIN',
		'Administrator',
		'Administracija',
		[
			['user', 'Račun'],
			['photo', 'Fotografije']
		],
		titleRow('Dobrodošli', 'Stanje biblioteke i poslužitelja na jednom mjestu.') +
			`<div class="stats">${stat('Korisnici', '0')}${stat('Fotke', '0')}${stat('Videi', '0')}${stat('Pohrana', '0 B', '', 0)}</div>` +
			`<div class="grid2">${card('Poslovi', emptyState('list', 'Nema poslova u redu.'))}${card('Sustav', kv('Verzija', 'test') + kv('Baza', 'PostgreSQL 17.0') + kv('Slobodno na disku', '0 B'))}</div>`
	);
}

export function loginPage(theme: string) {
	return document(
		theme,
		'auth-page auth-split',
		`<main class="as" id="main"><section class="as-l"><div class="as-top">${logo()}<div class="auth-tools as-tools-m">${langMenu}${themeBtn}</div></div><div class="as-form"><h1 class="as-h">Dobrodošli</h1><p class="as-p">Prijavite se svojim računom.</p><form class="as-f"><label class="as-fl"><span>E-adresa</span><input class="as-in" type="email" name="email"></label><label class="as-fl"><span>Lozinka</span><span class="as-pw"><input class="as-in" type="password" name="password"><button type="button" class="as-eye">${ico('eye')}</button></span></label><button class="as-btn" type="submit">Prijavi se</button></form><p class="as-links"><a href="#">Zaboravljena lozinka?</a></p><p class="as-legal"><a href="#">← mediarr.app</a></p></div></section>` +
			`<aside class="as-r"><div class="as-rtop">${langMenu}${themeBtn}<a class="as-cta" href="#">mediarr.app</a></div><div class="as-globe" aria-hidden="true"></div><div class="as-promo"><span class="as-eb">Mediarr</span><h2>Sve vaše fotke i videi, na vašem poslužitelju.</h2><p>Fotke · albumi · ljudi · karta</p></div></aside></main>`
	);
}

export function componentsPage(theme: string) {
	const buttons = `<div class="btn-row"><button class="btn">Obični</button><button class="btn gold">${ico('plus', 14)} Zlatni</button><button class="btn danger">Opasni</button><button class="btn sm">Mali</button><button class="btn" disabled>Isključen</button></div>`;
	const forms = `<div class="form grid-f"><label class="f"><span>E-adresa</span><input class="in" type="email" placeholder="ime@primjer.hr"><small class="hint">Pomoćni tekst</small></label><label class="f"><span>Lozinka</span><span class="pw"><input class="in" type="password"><button type="button" class="pw-t">${ico('eye')}</button></span></label><label class="f"><span>Uloga</span><select class="in"><option>Gledatelj</option><option>Urednik</option></select></label><div class="f"><span>Opcije</span><label class="chk"><input type="checkbox" checked> Zapamti me</label></div></div>`;
	const tabs = `<div class="tabs sm" role="tablist"><a class="tab on" href="#">Prva</a><a class="tab" href="#">Druga</a></div>`;
	const misc =
		tabs +
		alert('ok', 'Uspjeh') +
		alert('warn', 'Upozorenje') +
		alert('err', 'Greška') +
		`<div class="btn-row">${badge('Obična')}${badge('OK', 'ok')}${badge('Upozorenje', 'warn')}${badge('Loše', 'bad')}${badge('Naglasak', 'acc')}<span class="av" aria-hidden="true">DK</span></div>`;
	const table = `<div class="tbl-w"><table class="tbl"><thead><tr><th>Naziv</th><th>Status</th><th class="ta-r">Veličina</th></tr></thead><tbody><tr><td data-l="Naziv"><b>IMG_0001.heic</b></td><td data-l="Status">${badge('Verificirano', 'ok')}</td><td data-l="Veličina" class="ta-r">3,2 MB</td></tr><tr><td data-l="Naziv"><b>VID_0002.mov</b></td><td data-l="Status">${badge('U redu', 'warn')}</td><td data-l="Veličina" class="ta-r">120 MB</td></tr></tbody></table></div><nav class="pager"><button class="btn sm">←</button><button class="btn sm">1</button><button class="btn sm gold">2</button><button class="btn sm">3</button><button class="btn sm">4</button><button class="btn sm">→</button><span class="mute sm-t">ukupno 120</span></nav>`;
	return document(
		theme,
		'',
		`<main class="main" id="main"><div class="ph"><div><h1>Komponente</h1><p>Sve komponente design systema.</p></div><div class="ph-a">${themeBtn}</div></div><div id="zip-components">${card('Gumbi', buttons)}${card('Obrasci', forms)}${card('Kartice', misc)}<div class="stats">${stat('Fotke', '1.204', 'ovaj mjesec 32')}${stat('Videi', '86')}${stat('Pohrana', '42 GB', '', 42)}${stat('Disk', '95 %', '', 95)}</div><div class="grid2">${card('Podaci', kv('Verzija', '0.1.0') + kv('Baza', 'PostgreSQL 17') + bar(80))}${card('Prazno stanje', emptyState('album', 'Još nema albuma.', '<button class="btn sm gold">Novi album</button>'))}</div>${card('Tablica', table)}</div></main>`
	);
}
