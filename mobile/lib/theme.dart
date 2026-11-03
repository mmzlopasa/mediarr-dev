import 'package:flutter/material.dart';

/// The colors of the Mediarr design system (web/src/lib/design/dash.css), dark theme.
abstract final class Palette {
  static const bg = Color(0xFF0D0F14);
  static const bg2 = Color(0xFF161922);
  static const bg3 = Color(0xFF20242F);
  static const ink = Color(0xFFF3F5F7);
  static const haze = Color(0xFFAEB4C0);
  static const dim = Color(0xFF7C8391);
  static const line = Color(0x14FFFFFF);
  static const line2 = Color(0x29FFFFFF);
  static const violet = Color(0xFF8B7CFF);
  static const gold = Color(0xFFFFD76A);
  static const gold2 = Color(0xFFFFF0B8);
  static const gold3 = Color(0xFFE9B84A);
  static const onGold = Color(0xFF1B1530);
  static const ok = Color(0xFF8EF0C8);
  static const warn = Color(0xFFFFC98A);
  static const err = Color(0xFFFF9AA8);
}

const goldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Palette.gold2, Palette.gold, Palette.gold3],
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

ThemeData buildTheme() {
  final scheme = const ColorScheme.dark(
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
    borderSide: const BorderSide(color: Palette.line2),
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
      fillColor: const Color(0x0DFFFFFF),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Palette.gold),
      ),
      labelStyle: _text(14, 500, Palette.haze),
      hintStyle: _text(14, 400, Palette.dim),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.bg2,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0x33FFD76A),
      labelTextStyle: WidgetStateProperty.all(_text(12, 500, Palette.haze)),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Palette.bg2),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.bg2,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
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
