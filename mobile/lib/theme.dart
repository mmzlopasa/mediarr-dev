import 'package:flutter/material.dart';

/// The colors of the Mediarr design system (web/src/lib/design/dash.css), dark theme.
abstract final class Palette {
  /// Set by the app when the theme changes, before anything is drawn with these.
  static bool light = false;

  static Color _pick(int dark, int bright) => Color(light ? bright : dark);

  static Color get bg => _pick(0xFF0D0F14, 0xFFEEF0F3);
  static Color get bg2 => _pick(0xFF161922, 0xFFE4E7EC);
  static Color get bg3 => _pick(0xFF20242F, 0xFFD8DCE3);
  static Color get ink => _pick(0xFFF3F5F7, 0xFF12141A);
  static Color get haze => _pick(0xFFAEB4C0, 0xFF4A505C);
  static Color get dim => _pick(0xFF7C8391, 0xFF646A77);
  static Color get line => _pick(0x14FFFFFF, 0x1A12141A);
  static Color get line2 => _pick(0x29FFFFFF, 0x2E12141A);
  static Color get violet => _pick(0xFF8B7CFF, 0xFF5A49E6);

  /// The accent: gold on dark. Gold has no contrast on a light background, so there it is violet.
  static Color get gold => _pick(0xFFFFD76A, 0xFF5A49E6);
  static Color get field => _pick(0x0DFFFFFF, 0xD9FFFFFF);
  static Color get ok => _pick(0xFF8EF0C8, 0xFF0B8F69);
  static Color get warn => _pick(0xFFFFC98A, 0xFFA85D00);
  static Color get err => _pick(0xFFFF9AA8, 0xFFC62A47);

  /// These belong to the gold button, which looks the same in both themes.
  static const buttonGold = Color(0xFFFFD76A);
  static const gold2 = Color(0xFFFFF0B8);
  static const gold3 = Color(0xFFE9B84A);
  static const onGold = Color(0xFF1B1530);
}

const goldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Palette.gold2, Palette.buttonGold, Palette.gold3],
  stops: [0, 0.55, 1],
);

TextStyle _text(double size, double weight, Color color) => TextStyle(
  fontFamily: 'Sora',
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
    onPrimary: Palette.onGold,
    secondary: Palette.violet,
    error: Palette.err,
    onSurface: Palette.ink,
    outline: Palette.line2,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Palette.line2),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    fontFamily: 'Sora',
    splashFactory: NoSplash.splashFactory,
    textTheme: TextTheme(
      headlineMedium: _text(30, 500, Palette.ink),
      titleLarge: _text(20, 500, Palette.ink),
      titleMedium: _text(16, 600, Palette.ink),
      bodyLarge: _text(15, 400, Palette.ink),
      bodyMedium: _text(14, 400, Palette.haze),
      bodySmall: _text(12.5, 400, Palette.dim),
      labelLarge: _text(14.5, 600, Palette.ink),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.bg,
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
      indicatorColor: Palette.gold.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(_text(12, 500, Palette.haze)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Palette.bg2),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Palette.bg2,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.bg3,
      contentTextStyle: TextStyle(fontFamily: 'Sora', color: Palette.ink),
    ),
  );
}

/// The gold call-to-action button of the design system.
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
          gradient: goldGradient,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
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
