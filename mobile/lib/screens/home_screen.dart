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
      extendBody: true,
      bottomNavigationBar: _FloatingNav(
        selected: _tab,
        onSelected: (value) => setState(() => _tab = value),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.selected, required this.onSelected});

  static const _items = [
    (Icons.photo_outlined, Icons.photo, 'Media'),
    (Icons.search, Icons.search, 'Search'),
    (Icons.photo_album_outlined, Icons.photo_album, 'Albums'),
    (Icons.grid_view_outlined, Icons.grid_view, 'Library'),
  ];

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(bottom: 8),
    child: GlassCard(
      radius: 20,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // The place you are in is a quiet raised tile, as in the web's dock.
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: i == selected ? Palette.bg3 : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          i == selected ? _items[i].$2 : _items[i].$1,
                          size: 21,
                          color: i == selected ? Palette.ink : Palette.dim,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].$3,
                          style: TextStyle(
                            fontFamily: 'Inter Tight',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: i == selected ? Palette.ink : Palette.dim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
