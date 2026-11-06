/* Motion for mediarr.app with GSAP (ScrollTrigger, SplitText) and Lenis. Everything shows at once
   when the visitor asks for less motion, and if any of this fails to load. */
(function () {
	var root = document.documentElement;

	document.querySelector('[data-theme-btn]').addEventListener('click', function () {
		var next = root.dataset.theme === 'dark' ? 'light' : 'dark';
		root.dataset.theme = next;
		try {
			localStorage.setItem('mediarr_theme', next);
		} catch (e) {
			// Storage can be blocked; the theme still applies to this page.
		}
	});

	var copy = document.querySelector('[data-copy]');
	if (copy) {
		copy.addEventListener('click', function () {
			var text = copy.parentElement.querySelector('code').textContent;
			navigator.clipboard.writeText(text).then(function () {
				copy.textContent = 'Copied';
				setTimeout(function () {
					copy.textContent = 'Copy';
				}, 1600);
			});
		});
	}

	// The top row steps out of the way while reading down, and comes back on the way up.
	var nav = document.querySelector('.lx-nav');
	var lastY = 0;
	addEventListener(
		'scroll',
		function () {
			var y = scrollY;
			nav.classList.toggle('lx-away', y > 400 && y > lastY);
			lastY = y;
		},
		{ passive: true }
	);

	var show = function () {
		root.classList.add('lx-ready');
	};
	if (!root.classList.contains('lx-motion') || !window.gsap || !window.ScrollTrigger) {
		show();
		return;
	}
	// Never keep the page hidden waiting for fonts or code.
	setTimeout(show, 1500);

	var gsap = window.gsap;
	var ScrollTrigger = window.ScrollTrigger;
	var SplitText = window.SplitText;
	gsap.registerPlugin(ScrollTrigger, SplitText);

	var fine = matchMedia('(pointer: fine)').matches;
	if (window.Lenis && fine) {
		var lenis = new window.Lenis({ lerp: 0.1, smoothWheel: true, anchors: { offset: -20 } });
		lenis.on('scroll', ScrollTrigger.update);
		gsap.ticker.add(function (time) {
			lenis.raf(time * 1000);
		});
		gsap.ticker.lagSmoothing(0);
	}

	var start = function () {
		show();

		// Titles rise out of their lines; the first one at once, the others as they arrive.
		document.querySelectorAll('[data-split]').forEach(function (title, index) {
			var split = SplitText.create(title, {
				type: 'lines,words,chars',
				mask: 'lines',
				aria: 'auto',
				linesClass: 'lx-mask'
			});
			gsap.from(split.chars, {
				yPercent: 115,
				duration: index === 0 ? 1.1 : 0.9,
				ease: 'expo.out',
				stagger: index === 0 ? 0.022 : 0.016,
				delay: index === 0 ? 0.1 : 0,
				scrollTrigger: index === 0 ? undefined : { trigger: title, start: 'top 85%', once: true }
			});
		});

		gsap.from('[data-rise]', { autoAlpha: 0, y: 22, duration: 0.9, ease: 'power3.out', delay: 0.55 });
		gsap.from('.lx-edge', { scaleY: 0, duration: 1.6, ease: 'expo.out', delay: 0.2 });

		// The library comes forward and flattens into place as the page scrolls: the photos become
		// the interface.
		gsap.fromTo(
			'.lx-shot',
			{ rotateX: 14, scale: 0.86, y: 60 },
			{
				rotateX: 0,
				scale: 1,
				y: 0,
				ease: 'none',
				scrollTrigger: { trigger: '.lx-stage', start: 'top 92%', end: 'top 12%', scrub: true }
			}
		);

		// The statement fills in word by word as it is read.
		document.querySelectorAll('[data-words]').forEach(function (text) {
			var words = SplitText.create(text, { type: 'words', aria: 'auto' }).words;
			gsap.fromTo(
				words,
				{ opacity: 0.16 },
				{
					opacity: 1,
					ease: 'none',
					stagger: 0.05,
					scrollTrigger: { trigger: text, start: 'top 78%', end: 'bottom 50%', scrub: true }
				}
			);
		});

		// Features: on a wide screen the page scrolls them sideways while the row stays in place.
		var media = gsap.matchMedia();
		media.add('(min-width: 900px)', function () {
			var track = document.querySelector('.lx-tour-track');
			var distance = function () {
				return track.scrollWidth - innerWidth;
			};
			var slide = gsap.to(track, {
				x: function () {
					return -distance();
				},
				ease: 'none',
				scrollTrigger: {
					trigger: '.lx-tour',
					start: 'top top',
					end: function () {
						return '+=' + distance();
					},
					pin: true,
					scrub: 0.6,
					invalidateOnRefresh: true
				}
			});
			document.querySelectorAll('.lx-panel-shot img').forEach(function (picture) {
				gsap.fromTo(
					picture,
					{ xPercent: -1.5 },
					{
						xPercent: 1.5,
						ease: 'none',
						scrollTrigger: {
							trigger: picture,
							containerAnimation: slide,
							start: 'left right',
							end: 'right left',
							scrub: true
						}
					}
				);
			});
		});
		media.add('(max-width: 899px)', function () {
			gsap.utils.toArray('.lx-panel').forEach(function (panel) {
				gsap.from(panel, {
					autoAlpha: 0,
					y: 30,
					duration: 0.8,
					ease: 'power3.out',
					scrollTrigger: { trigger: panel, start: 'top 88%', once: true }
				});
			});
		});

		// Cards come in as a wave.
		ScrollTrigger.batch('.lx-fact', {
			once: true,
			start: 'top 92%',
			onEnter: function (batch) {
				gsap.fromTo(
					batch,
					{ autoAlpha: 0, y: 24 },
					{ autoAlpha: 1, y: 0, duration: 0.7, ease: 'power3.out', stagger: 0.07 }
				);
			}
		});

		// The name at the foot rises letter by letter.
		var word = SplitText.create('.lx-word', { type: 'chars', mask: 'chars' });
		gsap.from(word.chars, {
			yPercent: 100,
			duration: 1.2,
			ease: 'expo.out',
			stagger: 0.05,
			scrollTrigger: { trigger: '.lx-foot', start: 'top 90%', once: true }
		});

		// Gold buttons lean toward the mouse (after React Bits Magnet).
		if (fine) {
			document.querySelectorAll('[data-magnet]').forEach(function (button) {
				var toX = gsap.quickTo(button, 'x', { duration: 0.5, ease: 'elastic.out(1, 0.5)' });
				var toY = gsap.quickTo(button, 'y', { duration: 0.5, ease: 'elastic.out(1, 0.5)' });
				button.addEventListener('pointermove', function (event) {
					var box = button.getBoundingClientRect();
					toX((event.clientX - box.left - box.width / 2) * 0.25);
					toY((event.clientY - box.top - box.height / 2) * 0.35);
				});
				button.addEventListener('pointerleave', function () {
					toX(0);
					toY(0);
				});
			});
		}
	};

	if (document.fonts && document.fonts.ready) document.fonts.ready.then(start);
	else start();
})();
