import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The colours of the Lightbox design (web/src/lib/design/dash.css tokens): grey grounds, light
/// blue for what is on or chosen, gold for the button that acts.
abstract final class Palette {
  /// Set by the app when the theme changes, before anything is drawn with these.
  static bool light = false;

  static Color _pick(int dark, int bright) => Color(light ? bright : dark);

  static Color get bg => _pick(0xFF0D0F14, 0xFFEEF0F3);
  static Color get bg2 => _pick(0xFF161922, 0xFFE4E7EC);
  static Color get bg3 => _pick(0xFF20242F, 0xFFD8DCE3);
  static Color get ink => _pick(0xFFF3F5F7, 0xFF12141A);
  static Color get haze => _pick(0xFFAEB4C0, 0xFF3F4550);
  static Color get dim => _pick(0xFF8A91A0, 0xFF5C6370);
  static Color get line => _pick(0xFF232733, 0xFFD3D7DE);
  static Color get line2 => _pick(0xFF323846, 0xFFC0C5CF);

  /// The second colour, for avatars and quiet highlights.
  static Color get violet => _pick(0xFF8B7CFF, 0xFF5A49E6);

  /// The accent for what is on or chosen: light blue unless the person chose another.
  static Color get gold => _pick(accentDark, accentLight);

  /// The chosen accent, set by the app with the theme.
  static int accentDark = 0xFFC4BBFF;
  static int accentLight = 0xFF5A49E6;
  static Color get glassEdge => line;

  /// Surfaces are solid: glass reads poorly over photos and costs too much on older phones.
  static List<Color> get glass => [bg2, bg2];
  static Color get field => _pick(0xFF0F1218, 0xFFFFFFFF);
  static Color get ok => _pick(0xFF8EF0C8, 0xFF0B8F69);
  static Color get warn => _pick(0xFFFFC98A, 0xFFA85D00);
  static Color get err => _pick(0xFFFF9AA8, 0xFFC62A47);

  /// The gold button, which looks the same in both themes.
  static const buttonGold = Color(0xFFFFD76A);
  static const gold2 = Color(0xFFFFE28F);
  static const gold3 = Color(0xFFE9B84A);
  static const onGold = Color(0xFF1B1530);

  /// Text on the accent: dark on light blue, white on the deeper blue of the light theme.
  static Color get onAccent => _pick(0xFF1B1530, 0xFFFFFFFF);
}

/// Kept as a gradient for the screens that ask for one; it is a single colour.
const goldGradient = LinearGradient(
  colors: [Palette.buttonGold, Palette.buttonGold],
);

/// Titles: months, people, albums. Upright, never italic.
TextStyle serifTitle(double size, {Color? color}) => TextStyle(
  fontFamily: 'Instrument Serif',
  fontSize: size,
  height: 0.95,
  letterSpacing: -0.4,
  color: color ?? Palette.ink,
);

/// Data from the camera and the file, never words.
TextStyle monoData(double size, {Color? color}) => TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: size,
  color: color ?? Palette.ink,
);

TextStyle _text(double size, double weight, Color color) => TextStyle(
  fontFamily: 'Inter Tight',
  fontSize: size,
  color: color,
  fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
  fontVariations: [FontVariation('wght', weight)],
  letterSpacing: -0.1,
);

ThemeData buildTheme({bool light = false}) {
  final was = Palette.light;
  Palette.light = light;
  try {
    return _build(light);
  } finally {
    Palette.light = was;
  }
}

ThemeData _build(bool light) {
  final scheme = (light ? ColorScheme.light : ColorScheme.dark)(
    surface: Palette.bg,
    primary: Palette.gold,
    onPrimary: Palette.onAccent,
    secondary: Palette.violet,
    error: Palette.err,
    onSurface: Palette.ink,
    outline: Palette.line2,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Palette.line2),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    segmentedButtonTheme: SegmentedButtonThemeData(
      selectedIcon: const SizedBox.shrink(),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.gold
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.onAccent
              : Palette.ink,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: Palette.line2)),
      ),
    ),
    dividerTheme: DividerThemeData(color: Palette.line, thickness: 1, space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: _SkyPageTransitions(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.android: _SkyPageTransitions(
          ZoomPageTransitionsBuilder(),
        ),
      },
    ),
    fontFamily: 'Inter Tight',
    splashFactory: NoSplash.splashFactory,
    textTheme: TextTheme(
      headlineMedium: serifTitle(30),
      titleLarge: _text(20, 500, Palette.ink),
      titleMedium: _text(16, 600, Palette.ink),
      bodyLarge: _text(15, 400, Palette.ink),
      bodyMedium: _text(14, 400, Palette.haze),
      bodySmall: _text(12.5, 400, Palette.dim),
      labelLarge: _text(14.5, 600, Palette.ink),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: _text(20, 500, Palette.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.field,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: Palette.gold),
      ),
      labelStyle: _text(14, 500, Palette.haze),
      hintStyle: _text(14, 400, Palette.dim),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.bg2,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Palette.bg3,
      labelTextStyle: WidgetStateProperty.all(_text(12, 500, Palette.haze)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Palette.bg2),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Palette.bg2,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.bg3,
      contentTextStyle: TextStyle(
        fontFamily: 'Inter Tight',
        color: Palette.ink,
      ),
    ),
  );
}

/// The page behind everything: the darkroom's plain ground, so photos keep their own colours.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Palette.bg, child: child);
}

/// Screens are see-through, for the sky behind them. While one slides over another, each brings its
/// own sky, or the two would show through each other.
class _SkyPageTransitions extends PageTransitionsBuilder {
  const _SkyPageTransitions(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    SkyBackground(child: child),
  );
}

/// A raised surface: solid, with one soft shadow where it floats.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Palette.line),
      color: Palette.bg2,
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 32,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

/// The design's round icon. When it is on, it takes the accent.
class RingIcon extends StatelessWidget {
  const RingIcon(this.icon, {super.key, this.on = false, this.size = 38});

  final IconData icon;
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.bg3),
    child: Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Icon(
        icon,
        size: size * 0.5,
        color: on ? Palette.gold : Palette.ink,
      ),
    ),
  );
}

/// The accent call-to-action button of the design system.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.buttonGold,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Palette.onGold,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: 18, color: Palette.onGold),
                  if (busy || icon != null) const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: Palette.onGold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of invented content when there is nothing to show.
class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Palette.dim),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
