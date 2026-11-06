import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motion in the app, the same moments as on the web (web/src/lib/motion): a title rises out of its
/// line, cards come in as a wave the first time, numbers count up, the favourite pulses. Never on
/// what is used all the time (the timeline as it scrolls, the viewer's swipes), and nothing when
/// the phone asks for less motion.
bool motionOff(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

const _riseCurve = Cubic(0.16, 1, 0.3, 1);

/// A title rises out of its own line, once, when the screen opens.
class TitleRise extends StatefulWidget {
  const TitleRise({super.key, required this.child});

  final Widget child;

  @override
  State<TitleRise> createState() => _TitleRiseState();
}

class _TitleRiseState extends State<TitleRise>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionOff(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 1.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: _riseCurve)),
      child: widget.child,
    ),
  );
}

/// Cards that were already shown in this run of the app, so scrolling back does not replay them.
final _seen = <String>{};

/// A card fades in and rises 14 points the first time it appears, a little after the one before.
class Rise extends StatefulWidget {
  const Rise({
    super.key,
    required this.id,
    required this.index,
    required this.child,
  });

  /// What the card shows, so the same card does not rise twice.
  final String id;

  /// Its place in the list: the first screenful comes in one after another.
  final int index;
  final Widget child;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value > 0 || _controller.isAnimating) return;
    if (motionOff(context) || _seen.contains(widget.id)) {
      _controller.value = 1;
      return;
    }
    _seen.add(widget.id);
    final wait = Duration(milliseconds: 50 * math.min(widget.index, 12));
    Future<void>.delayed(wait, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// A number counts up to its value; the real value is what screen readers hear.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.format, this.style});

  final num value;
  final String Function(num value)? format;
  final TextStyle? style;

  String _text(num value) => format?.call(value) ?? '${value.round()}';

  @override
  Widget build(BuildContext context) {
    if (motionOff(context) || value == 0) {
      return Text(_text(value), style: style);
    }
    return Semantics(
      label: _text(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (context, now, _) =>
            Text(_text(now == value ? value : now), style: style),
      ),
    );
  }
}

/// The icon shrinks to a dot, takes its new state and springs back past its size, when [on]
/// changes: the moment a picture becomes a favourite.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  static double _swell(double t) {
    const turn = 0.4;
    const overshoot = 1.7;
    double back(double k) {
      final u = k - 1;
      return 1 + (overshoot + 1) * u * u * u + overshoot * u * u;
    }

    if (t <= 0) return 0;
    if (t < turn) return 1 - math.pow(1 - t / turn, 3).toDouble();
    return 1 - back((t - turn) / (1 - turn));
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    if (old.on != widget.on && !motionOff(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.scale(
      scale: _controller.isAnimating ? 1 - 0.7 * _swell(_controller.value) : 1,
      child: child,
    ),
  );
}
