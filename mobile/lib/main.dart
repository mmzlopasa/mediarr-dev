import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
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
    final theme = ref.watch(settingsProvider).theme;
    return MaterialApp(
      title: 'Mediarr',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(light: true),
      darkTheme: buildTheme(),
      themeMode: switch (theme) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
      },
      builder: (context, child) {
        final light = Theme.of(context).brightness == Brightness.light;
        if (Palette.light != light) {
          Palette.light = light;
          SystemChrome.setSystemUIOverlayStyle(
            light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _redrawAll(context),
          );
        }
        return child ?? const SizedBox.shrink();
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
                    fontFamily: 'Sora',
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

/// Colors come from Palette, not from an inherited theme, so everything has to be told.
void _redrawAll(BuildContext context) {
  void visit(Element element) {
    element.markNeedsBuild();
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}
