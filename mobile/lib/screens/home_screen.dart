import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/backup.dart';
import '../services/session.dart';
import '../services/settings.dart';
import '../services/shared_files.dart';
import '../services/uploads.dart';
import '../theme.dart';
import 'server_status.dart';
import 'albums_screen.dart';
import 'timeline_screen.dart';
import 'app_header.dart';
import 'library_screen.dart';
import 'people_screens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(sessionProvider).value;
      if (mounted && session != null) {
        unawaited(showUpdateNoticeIfNew(context, session));
      }
    });
    SharedFilesChannel.listen((files) {
      if (!mounted) return;
      ref.read(uploadsProvider.notifier).addShared(files);
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const UploadPage()));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recheckServer());
      unawaited(_mirrorAlbums());
    }
  }

  Future<void> _mirrorAlbums() async {
    final settings = ref.read(settingsProvider);
    final session = ref.read(sessionProvider).value;
    if (!settings.mirrorAlbums || settings.readOnly || session == null) return;
    try {
      final phone = await ref.read(backupProvider).albumChecksums();
      await mirrorAlbums(session.api, phone);
    } on ApiException {
      // Next time: nothing is lost, as only the album membership waits.
    } on MissingPluginException {
      // No native backup on this platform.
    } on PlatformException {
      // The same.
    }
  }

  Future<void> _recheckServer() async {
    final moved = await ref.read(sessionProvider.notifier).recheckServer();
    if (moved == null) return;
    try {
      await ref.read(backupProvider).setServer(moved);
    } on MissingPluginException {
      // No native backup on this platform.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          TimelineScreen(),
          SearchScreen(),
          AlbumsScreen(),
          LibraryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: Palette.gold),
            label: 'Media',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Palette.gold),
            label: 'Search',
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo_album_outlined),
            selectedIcon: Icon(Icons.photo_album, color: Palette.gold),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Palette.gold),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
