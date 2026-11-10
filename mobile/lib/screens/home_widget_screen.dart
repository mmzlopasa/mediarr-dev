import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/home_widget.dart';
import '../services/session.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

/// How to put the widget on the home screen, for this phone.
String widgetHowTo() => Platform.isIOS
    ? l.homeWidgetScreenHowToIos
    : l.homeWidgetScreenHowToAndroid;

/// How many pictures the widget keeps, where the phone says: on iOS the widget fetches them itself.
String widgetPicturesLine(int pictures) => switch (pictures) {
  < 0 => l.homeWidgetScreenFetchesItself,
  0 => l.homeWidgetScreenFetching,
  _ => l.homeWidgetScreenPicturesKept(pictures),
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
  WidgetInstall? _install;
  List<Album>? _albums;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final choice = await _widget.status();
    final install = Platform.isIOS ? await _widget.install() : null;
    List<Album>? albums;
    try {
      albums = await _session.api.listAlbums(sort: 'title');
    } on ApiException {
      albums = const [];
    }
    if (!mounted) return;
    setState(() {
      _choice = choice;
      _install = install;
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
      _say(cause.message ?? l.homeWidgetScreenDidNotWork);
    } on PlatformException {
      _say(l.homeWidgetScreenDidNotWork);
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
      appBar: AppBar(title: Text(l.homeWidgetScreenTitle)),
      body: choice == null || albums == null
          ? Center(child: CircularProgressIndicator(color: Palette.gold))
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    l.homeWidgetScreenIntro(widgetHowTo()),
                    style: text.bodyMedium,
                  ),
                ),
                if (_install case final install?)
                  WidgetInstallTile(install: install),
                if (choice.chosen)
                  ListTile(
                    leading: Icon(Icons.widgets_outlined, color: Palette.gold),
                    title: Text(l.homeWidgetScreenShowing(choice.albumTitle)),
                    subtitle: Text(widgetPicturesLine(choice.pictures)),
                    trailing: TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => _widget.clear(_session),
                              l.homeWidgetScreenShowsNothing,
                            ),
                      child: Text(l.homeWidgetScreenTurnOff),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(l.homeWidgetScreenAlbum, style: text.titleSmall),
                ),
                if (albums.isEmpty)
                  ListTile(title: Text(l.homeWidgetScreenNoAlbums)),
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
                      l.homeWidgetScreenShows(album.title),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Says whether iOS can offer the widget, and if not, why.
class WidgetInstallTile extends StatelessWidget {
  const WidgetInstallTile({super.key, required this.install});

  final WidgetInstall install;

  @override
  Widget build(BuildContext context) {
    final verdict = install.verdict;
    if (verdict == WidgetInstallVerdict.unknown) return const SizedBox.shrink();
    final fine = verdict == WidgetInstallVerdict.fine;
    final message = switch (verdict) {
      WidgetInstallVerdict.missing => l.widgetInstallMissing,
      WidgetInstallVerdict.unsigned => l.widgetInstallUnsigned,
      _ => l.widgetInstallFine,
    };
    return ListTile(
      key: const ValueKey('widget-install'),
      leading: Icon(
        fine ? Icons.check_circle_outline : Icons.error_outline,
        color: fine ? Palette.gold : Theme.of(context).colorScheme.error,
      ),
      title: Text(l.widgetInstallTitle),
      subtitle: Text(message),
    );
  }
}
