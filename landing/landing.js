/* Concept 1. Without GSAP, or with reduced motion, everything is simply there. */
(function () {
	var root = document.documentElement;

	// Phone menu
	var menuBtn = document.querySelector('[data-menu]');
	var menu = document.getElementById('menu');
	menuBtn.addEventListener('click', function () {
		var open = menuBtn.getAttribute('aria-expanded') !== 'true';
		menuBtn.setAttribute('aria-expanded', String(open));
		menu.classList.toggle('open', open);
	});
	menu.addEventListener('click', function (e) {
		if (e.target.closest('a')) {
			menuBtn.setAttribute('aria-expanded', 'false');
			menu.classList.remove('open');
		}
	});

	// Copy the install commands
	var copy = document.querySelector('[data-copy]');
	copy.addEventListener('click', function () {
		var text = copy.parentElement.querySelector('code').textContent;
		navigator.clipboard.writeText(text).then(function () {
			copy.textContent = 'Copied';
			setTimeout(function () {
				copy.textContent = 'Copy';
			}, 1600);
		});
	});

	// The top row gets its ground once the page moves.
	var top = document.querySelector('[data-top]');
	var onScroll = function () {
		top.classList.toggle('solid', scrollY > 24);
	};
	addEventListener('scroll', onScroll, { passive: true });
	onScroll();

	// The film edge marks the part of the page in view.
	var marks = Array.prototype.slice.call(document.querySelectorAll('[data-edge] a'));
	var sections = Array.prototype.slice.call(document.querySelectorAll('[data-section]'));
	var light = function () {
		var mid = innerHeight * 0.4;
		var current = sections[0];
		sections.forEach(function (s) {
			if (s.getBoundingClientRect().top <= mid) current = s;
		});
		marks.forEach(function (m) {
			m.setAttribute('aria-current', m.getAttribute('href') === '#' + current.id ? 'true' : 'false');
		});
	};
	addEventListener('scroll', light, { passive: true });
	light();

	var lenis = null;
	// A jump on the film edge goes at once, as in the library.
	marks.forEach(function (m) {
		m.addEventListener('click', function (e) {
			var target = document.querySelector(m.getAttribute('href'));
			if (!target) return;
			e.preventDefault();
			if (lenis) lenis.scrollTo(target, { immediate: true });
			else target.scrollIntoView();
			history.replaceState(null, '', m.getAttribute('href'));
		});
	});

	var ready = function () {
		root.classList.add('m-ready');
	};
	if (!root.classList.contains('m') || !window.gsap) {
		ready();
		return;
	}
	var gsap = window.gsap;

	if (window.Lenis && matchMedia('(pointer: fine)').matches) {
		lenis = new window.Lenis({ lerp: 0.1, smoothWheel: true });
		gsap.ticker.add(function (t) {
			lenis.raf(t * 1000);
		});
		gsap.ticker.lagSmoothing(0);
	}

	// The print develops: blank paper first, then the shadows, then the tones, then colour.
	var img = document.querySelector('[data-print] img');
	var develop = function () {
		gsap.set(img, { opacity: 0, filter: 'grayscale(1) contrast(0.35) brightness(1.9)' });
		ready();
		gsap
			.timeline({ delay: 0.35 })
			.to(img, { opacity: 1, duration: 1.5, ease: 'power1.in' })
			.to(img, { filter: 'grayscale(1) contrast(1.2) brightness(1)', duration: 1.7, ease: 'power2.out' }, 0.7)
			.to(img, { filter: 'grayscale(0) contrast(1) brightness(1)', duration: 1.5, ease: 'power2.inOut' }, 2.1);
	};
	if (img.complete) develop();
	else {
		img.addEventListener('load', develop, { once: true });
		img.addEventListener('error', ready, { once: true });
	}
})();
