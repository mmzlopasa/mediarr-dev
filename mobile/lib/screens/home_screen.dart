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

/// The dock, as on the web: the places you go every day, the one you are in on midnight blue, and
/// the gold + that adds photos and videos (with how many are still going).
class _FloatingNav extends ConsumerWidget {
  const _FloatingNav({required this.selected, required this.onSelected});

  static const _items = [
    (Icons.photo_outlined, 'Media'),
    (Icons.search, 'Search'),
    (Icons.photo_album_outlined, 'Albums'),
    (Icons.grid_view_outlined, 'Library'),
  ];

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readOnly = ref.watch(settingsProvider).readOnly;
    final working = ref
        .watch(uploadsProvider)
        .where((task) => !task.finished)
        .length;
    return SafeArea(
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
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: i == selected
                            ? Palette.fill
                            : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _items[i].$1,
                            size: 21,
                            color: i == selected ? Palette.onFill : Palette.dim,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$2,
                            style: TextStyle(
                              fontFamily: 'Inter Tight',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: i == selected
                                  ? Palette.onFill
                                  : Palette.dim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!readOnly) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Add',
                child: Semantics(
                  button: true,
                  label: working > 0 ? 'Add, $working uploading' : 'Add',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UploadPage(),
                      ),
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.buttonGold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: working > 0
                          ? Text(
                              '$working',
                              style: const TextStyle(
                                fontFamily: 'Inter Tight',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Palette.onGold,
                              ),
                            )
                          : const Icon(Icons.add, color: Palette.onGold),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
