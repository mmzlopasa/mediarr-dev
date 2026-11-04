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
import 'account_screen.dart';
import 'albums_screen.dart';
import 'timeline_screen.dart';
import 'upload_screen.dart';

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
    SharedFilesChannel.listen((files) {
      if (!mounted) return;
      ref.read(uploadsProvider.notifier).addShared(files);
      setState(() => _tab = 2);
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
    final working = ref
        .watch(uploadsProvider)
        .where((task) => !task.finished)
        .length;
    final readOnly = ref.watch(settingsProvider).readOnly;
    const uploadTab = 2;
    final shown = [
      for (var i = 0; i < 4; i++)
        if (!readOnly || i != uploadTab) i,
    ];
    final tab = shown.contains(_tab) ? _tab : 0;
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [
          TimelineScreen(),
          AlbumsScreen(),
          UploadScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shown.indexOf(tab),
        onDestinationSelected: (value) => setState(() => _tab = shown[value]),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.photo_outlined),
            selectedIcon: Icon(Icons.photo, color: Palette.gold),
            label: 'Media',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_album_outlined),
            selectedIcon: Icon(Icons.photo_album, color: Palette.gold),
            label: 'Albums',
          ),
          if (!readOnly)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: working > 0,
                label: Text('$working'),
                child: const Icon(Icons.upload_outlined),
              ),
              selectedIcon: Icon(Icons.upload, color: Palette.gold),
              label: 'Upload',
            ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Palette.gold),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
