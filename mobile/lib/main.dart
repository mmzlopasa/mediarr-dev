import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/language.dart';
import 'services/session.dart';
import 'services/settings.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const ProviderScope(child: MediarrApp()));
}

class MediarrApp extends ConsumerWidget {
  const MediarrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(settingsProvider);
    final language = ref.watch(languageProvider);
    final languageChanged =
        _shownLanguage != null && _shownLanguage != language;
    _shownLanguage = language;
    final theme = settings.theme;
    final accentChanged = Palette.accentDark != settings.accent.onDark;
    Palette.accentDark = settings.accent.onDark;
    Palette.accentLight = settings.accent.onLight;
    return MaterialApp(
      title: 'Mediarr',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(light: true),
      darkTheme: buildTheme(),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: switch (theme) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
      },
      builder: (context, child) {
        final light = Theme.of(context).brightness == Brightness.light;
        if (accentChanged || languageChanged) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _redrawAll(context),
          );
        }
        if (Palette.light != light) {
          Palette.light = light;
          SystemChrome.setSystemUIOverlayStyle(
            light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _redrawAll(context),
          );
        }
        return SkyBackground(child: child ?? const SizedBox.shrink());
      },
      home: session.when(
        loading: () => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mediarr.',
                  style: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Palette.gold,
                  ),
                ),
                const SizedBox(height: 22),
                CircularProgressIndicator(color: Palette.gold),
              ],
            ),
          ),
        ),
        error: (_, _) => const LoginScreen(),
        data: (value) =>
            value == null ? const LoginScreen() : const HomeScreen(),
      ),
    );
  }
}

/// The language last shown; texts are read from a global, so a change redraws everything.
String? _shownLanguage;

/// Colors come from Palette, not from an inherited theme, so everything has to be told.
void _redrawAll(BuildContext context) {
  void visit(Element element) {
    element.markNeedsBuild();
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}
