import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/session.dart';
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
    return MaterialApp(
      title: 'Mediarr',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: session.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Palette.gold)),
        ),
        error: (_, _) => const LoginScreen(),
        data: (value) =>
            value == null ? const LoginScreen() : const HomeScreen(),
      ),
    );
  }
}
