<script lang="ts">
	import Icon from '#lib/design/components/Icon.svelte';
	import LangMenu from '#lib/design/components/LangMenu.svelte';
	import Logo from '#lib/design/components/Logo.svelte';
	import ThemeButton from '#lib/design/components/ThemeButton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';
	import { tr } from '#lib/i18n.svelte.ts';

	let visible = $state(false);

	$effect.pre(() => {
		document.body.className = 'auth-page auth-split';
		return () => {
			document.body.className = '';
		};
	});

	function submit(event: SubmitEvent) {
		event.preventDefault();
		showToast('warn', tr('Prijava još nije dostupna.', 'Sign-in is not available yet.'));
	}
</script>

<svelte:head><title>{tr('Prijava', 'Sign in')} — Mediarr</title></svelte:head>

<main class="as" id="main">
	<section class="as-l">
		<div class="as-top">
			<Logo />
			<div class="auth-tools as-tools-m"><LangMenu /><ThemeButton /></div>
		</div>
		<div class="as-form">
			<h1 class="as-h">{tr('Dobrodošli', 'Welcome')}</h1>
			<p class="as-p">{tr('Prijavite se svojim računom.', 'Sign in with your account.')}</p>
			<form class="as-f" autocomplete="on" onsubmit={submit}>
				<label class="as-fl">
					<span>{tr('E-adresa', 'Email')}</span>
					<input
						class="as-in"
						type="email"
						name="email"
						required
						autocomplete="username"
						inputmode="email"
					/>
				</label>
				<label class="as-fl">
					<span>{tr('Lozinka', 'Password')}</span>
					<span class="as-pw">
						<input
							class="as-in"
							type={visible ? 'text' : 'password'}
							name="password"
							required
							autocomplete="current-password"
						/>
						<button
							type="button"
							class="as-eye"
							aria-label={tr('Prikaži lozinku', 'Show password')}
							aria-pressed={visible}
							onclick={() => (visible = !visible)}><Icon name="eye" /></button
						>
					</span>
				</label>
				<button class="as-btn" type="submit">{tr('Prijavi se', 'Sign in')}</button>
			</form>
			<p class="as-links">
				<a href="#forgot">{tr('Zaboravljena lozinka?', 'Forgot your password?')}</a>
			</p>
			<p class="as-legal"><a href="https://mediarr.app">← mediarr.app</a></p>
		</div>
	</section>
	<aside class="as-r" aria-label="Mediarr">
		<div class="as-rtop">
			<LangMenu />
			<ThemeButton />
			<a class="as-cta" href="https://mediarr.app">mediarr.app</a>
		</div>
		<div class="as-globe" aria-hidden="true"></div>
		<div class="as-promo">
			<span class="as-eb">Mediarr</span>
			<h2>
				{tr(
					'Sve vaše fotke i videi, na vašem poslužitelju.',
					'All your photos and videos, on your own server.'
				)}
			</h2>
			<p>{tr('Fotke · albumi · ljudi · karta', 'Photos · albums · people · map')}</p>
		</div>
	</aside>
</main>
