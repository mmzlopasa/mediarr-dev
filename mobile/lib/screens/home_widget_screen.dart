import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/home_widget.dart';
import '../services/session.dart';
import '../theme.dart';

/// How to put the widget on the home screen, for this phone.
String widgetHowTo() => Platform.isIOS
    ? 'Then touch and hold an empty spot on the home screen, tap + (or Edit, Add Widget), '
          'and choose Mediarr.'
    : 'Then touch and hold an empty spot on the home screen, tap Widgets, and drag Mediarr to it.';

/// How many pictures the widget keeps, where the phone says: on iOS the widget fetches them itself.
String widgetPicturesLine(int pictures) => switch (pictures) {
  < 0 => 'The widget fetches its photos itself, and keeps a few.',
  0 => 'Fetching its photos…',
  1 => '1 photo kept on this phone for it',
  _ => '$pictures photos kept on this phone for it',
};

/// Chooses the album the home screen widget shows.
class HomeWidgetScreen extends ConsumerStatefulWidget {
  const HomeWidgetScreen({super.key, this.service});

  final HomeWidgetService? service;

  @override
  ConsumerState<HomeWidgetScreen> createState() => _HomeWidgetScreenState();
}

class _HomeWidgetScreenState extends ConsumerState<HomeWidgetScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  late final HomeWidgetService _widget = widget.service ?? HomeWidgetService();
  WidgetChoice? _choice;
  List<Album>? _albums;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final choice = await _widget.status();
    List<Album>? albums;
    try {
      albums = await _session.api.listAlbums(sort: 'title');
    } on ApiException {
      albums = const [];
    }
    if (!mounted) return;
    setState(() {
      _choice = choice;
      _albums = albums ?? const [];
    });
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      _say(done);
    } on ApiException catch (cause) {
      _say(cause.message ?? 'It did not work.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final choice = _choice;
    final albums = _albums;
    return Scaffold(
      appBar: AppBar(title: const Text('Home screen widget')),
      body: choice == null || albums == null
          ? Center(child: CircularProgressIndicator(color: Palette.gold))
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'The widget shows a photo from the album you choose here, a different one '
                    'every hour, also without a connection. ${widgetHowTo()}',
                    style: text.bodyMedium,
                  ),
                ),
                if (choice.chosen)
                  ListTile(
                    leading: Icon(Icons.widgets_outlined, color: Palette.gold),
                    title: Text('Showing ${choice.albumTitle}'),
                    subtitle: Text(widgetPicturesLine(choice.pictures)),
                    trailing: TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => _widget.clear(_session),
                              'The widget shows nothing now.',
                            ),
                      child: const Text('Turn off'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Album', style: text.titleSmall),
                ),
                if (albums.isEmpty)
                  const ListTile(title: Text('There are no albums yet.')),
                for (final album in albums)
                  ListTile(
                    leading: Icon(
                      album.id == choice.albumId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: album.id == choice.albumId ? Palette.gold : null,
                    ),
                    title: Text(album.title),
                    subtitle: Text('${album.assetCount}'),
                    enabled: !_busy,
                    onTap: () => _run(
                      () => _widget.choose(_session, album),
                      'The widget shows ${album.title}.',
                    ),
                  ),
              ],
            ),
    );
  }
}
