import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// The colours of the six photos in the mark, in the order they fan out.
const brandColors = [
  Color(0xFFFFC83D),
  Color(0xFFFF9F43),
  Color(0xFFFF5E57),
  Color(0xFFFF7EB6),
  Color(0xFF3A55C9),
  Color(0xFF2EC4A6),
];

/// The gold of the sun that dots the i.
const brandSun = Color(0xFFFFC83D);

/// The film edge under the name: one tick per month, in hundredths of the letter size.
const brandTicks = [
  10,
  16,
  7,
  22,
  12,
  18,
  9,
  14,
  20,
  8,
  15,
  11,
  17,
  6,
  13,
  19,
  9,
];

/// The tick under the i, drawn in gold.
const brandGoldTick = 10;

/// How long the fan takes to open, and one swell of the wave along the edge.
const brandOpen = Duration(milliseconds: 900);
const brandWave = Duration(milliseconds: 2400);

/// The film edge. [phase] runs from 0 to 1 and moves a wave along the ticks; null keeps them still.
class EdgePainter extends CustomPainter {
  const EdgePainter({required this.ink, this.phase});

  final Color ink;
  final double? phase;

  /// How tall tick [i] is drawn at [phase], as a share of its own length: a wave that travels along.
  static double swell(int i, double? phase) {
    if (phase == null) return 1;
    final wave = math.sin(2 * math.pi * (phase - i / 17 * 0.97));
    return 0.725 + 0.275 * wave;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // The same drawing as the web: a 326 by 28 box, ticks 6 wide every 20.
    canvas.scale(size.width / 326, size.height / 28);
    for (var i = 0; i < brandTicks.length; i++) {
      final h = brandTicks[i] * 1.196 * swell(i, phase);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 20.0, 28 - h, 6, h),
          const Radius.circular(3),
        ),
        Paint()
          ..color = i == brandGoldTick ? brandSun : ink.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(EdgePainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.phase != phase;
}

/// Mediarr's mark: six photos fanned out. Where they overlap, their light adds up on a dark ground
/// and their colours mix like ink on a light one, the same as on the web.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 24, this.open = 1});

  final double size;

  /// How far the fan has opened, from 0 (all six photos on top of each other) to 1.
  final double open;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: FanPainter(light: Palette.light, open: open),
    ),
  );
}

class FanPainter extends CustomPainter {
  const FanPainter({required this.light, this.open = 1});

  final bool light;
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    // The same drawing as the SVG: a 64-unit box, shown from 5 to 59.
    final scale = size.shortestSide / 54;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(scale);
    canvas.translate(-5, -5);
    final petal = RRect.fromRectAndRadius(
      const Rect.fromLTWH(27, 7, 13, 24),
      const Radius.circular(4),
    );
    for (var i = 0; i < brandColors.length; i++) {
      canvas
        ..save()
        ..translate(32, 32)
        ..rotate(i * math.pi / 3 * open)
        ..translate(-32, -32)
        ..drawRRect(
          petal,
          Paint()
            ..color = brandColors[i].withValues(alpha: .92)
            ..blendMode = light ? BlendMode.multiply : BlendMode.screen,
        )
        ..restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FanPainter oldDelegate) =>
      oldDelegate.light != light || oldDelegate.open != open;
}

/// The mark and the name, with a gold sun as the dot of the i and a film edge under it.
///
/// When it first appears the fan opens out of one photo and the name follows; after that the film
/// edge swells like a wave, over and over. With less motion asked for, it is simply there.
class BrandLogo extends StatefulWidget {
  const BrandLogo({super.key, this.size = 20, this.mark = true});

  final double size;
  final bool mark;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: brandOpen,
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: brandWave,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _open.value = 1;
      return;
    }
    _open.forward();
    _wave.repeat();
  }

  @override
  void dispose() {
    _open.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final style = TextStyle(
      fontFamily: 'Inter Tight',
      fontSize: size,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 620)],
      letterSpacing: -0.035 * size,
      color: Palette.ink,
    );
    final still = !_wave.isAnimating;
    return Semantics(
      label: 'Mediarr',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_open, _wave]),
        builder: (context, _) {
          final t = _open.value;
          final fan = Curves.easeOutCubic.transform(t);
          // The name comes in once the fan is halfway open.
          final name = Curves.easeOutCubic.transform(
            ((t - 0.35) / 0.65).clamp(0.0, 1.0),
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.mark) ...[
                BrandMark(size: size * 1.5, open: fan),
                SizedBox(width: size * 0.42),
              ],
              Opacity(
                opacity: name,
                child: Transform.translate(
                  offset: Offset(-0.3 * size * (1 - name), 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: style,
                          children: [
                            const TextSpan(text: 'med'),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Text('ı', style: style),
                                  Positioned(
                                    top: size * 0.08,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        width: size * 0.2,
                                        height: size * 0.2,
                                        decoration: const BoxDecoration(
                                          color: brandSun,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const TextSpan(text: 'arr'),
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: Size(size * 3.26, size * 0.28),
                        painter: EdgePainter(
                          ink: Palette.ink,
                          phase: still ? null : _wave.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
