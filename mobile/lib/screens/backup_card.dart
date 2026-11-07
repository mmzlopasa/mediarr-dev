import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/backup.dart';
import '../services/session.dart';
import '../theme.dart';
import 'devices_screen.dart';
import 'free_space_screen.dart';

String describeLastBackup(DateTime? last, DateTime now) {
  if (last == null) return 'Nothing has been backed up yet.';
  final age = now.difference(last);
  if (age.inMinutes < 1) return 'Last file backed up just now.';
  if (age.inHours < 1) return 'Last file backed up ${age.inMinutes} min ago.';
  if (age.inDays < 1) return 'Last file backed up ${age.inHours} h ago.';
  return 'Last file backed up ${age.inDays} d ago.';
}

/// The switch and the live state of the automatic backup.
class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key, this.onStatus});

  final void Function(BackupStatus status)? onStatus;

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  static const _pollEvery = Duration(seconds: 3);

  BackupStatus? _status;
  Timer? _poll;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(_pollEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final status = await ref.read(backupProvider).status();
      if (!mounted) {
        return;
      }
      setState(() => _status = status);
      widget.onStatus?.call(status);
    } on MissingPluginException {
      // Only the iOS app has the native engine so far.
    } on PlatformException catch (cause) {
      if (mounted) {
        setState(() => _error = cause.message);
      }
    }
  }

  Future<bool?> _askScope(String album) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Back up "$album"'),
      content: const Text(
        'Should photos already in this album be sent? Anything already on the server is '
        'never sent twice.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Only photos added from now'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Also the ones in it now'),
        ),
      ],
    ),
  );

  Future<AlbumChoice?> _pickAlbum() async {
    final albums = await ref.read(backupProvider).albums();
    if (!mounted) {
      return null;
    }
    return showModalBottomSheet<AlbumChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AlbumPicker(albums: albums),
    );
  }

  Future<void> _editAlbums() async {
    final service = ref.read(backupProvider);
    final status = _status;
    if (status == null) return;
    final albums = await service.albums();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<AlbumLists>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AlbumListsSheet(
        albums: albums,
        more: status.moreAlbums,
        excluded: status.excludedAlbums,
      ),
    );
    if (chosen == null) return;
    final added = chosen.more.any((id) => !status.moreAlbums.contains(id));
    final onlyNew = added ? await _askScope('the added albums') : false;
    if (onlyNew == null) return;
    await _run(() async {
      await service.setAlbumLists(
        more: chosen.more,
        excluded: chosen.excluded,
        onlyNew: onlyNew,
      );
    });
  }

  /// Backup only ever runs with a chosen album, so choosing comes first.
  Future<bool> _chooseAndApply({required bool enable}) async {
    final session = ref.read(sessionProvider).value;
    final service = ref.read(backupProvider);
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission != PermissionState.authorized) {
      setState(
        () => _error = 'Albums need access to all photos. Allow it in Settings: Mediarr > Photos > Full Access.',
      );
      return false;
    }
    final album = await _pickAlbum();
    if (album == null) {
      return false;
    }
    final onlyNew = await _askScope(album.name);
    if (onlyNew == null || session == null) {
      return false;
    }
    if (enable) {
      await service.enable(
        session,
        wifiOnly: _status?.wifiOnly ?? true,
        onlyNew: onlyNew,
        albumId: album.id,
        albumName: album.name,
      );
    } else {
      await service.setAlbum(
        albumId: album.id,
        albumName: album.name,
        onlyNew: onlyNew,
      );
    }
    return true;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } on ApiException catch (cause) {
      if (mounted) {
        setState(
          () => _error =
              'The server could not be reached. ${cause.message ?? ''}',
        );
      }
    } on PlatformException catch (cause) {
      if (mounted) {
        setState(() => _error = cause.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _toggle(bool value) => _run(() async {
    if (value) {
      await _chooseAndApply(enable: true);
    } else {
      await ref.read(backupProvider).disable(ref.read(sessionProvider).value);
    }
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = _status;
    if (status == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: Palette.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Automatic backup', style: text.titleMedium),
              ),
              Switch(
                value: status.enabled,
                activeTrackColor: Palette.gold,
                onChanged: _busy ? null : _toggle,
              ),
            ],
          ),
          if (status.enabled) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Album: ${status.albumName}',
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await _chooseAndApply(enable: false);
                        }),
                  child: const Text('Change'),
                ),
              ],
            ),
            if (!status.albumFound)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  status.limitedAccess
                      ? 'Albums need access to all photos. Allow it in Settings: '
                            'Mediarr > Photos > Full Access. Nothing is being sent.'
                      : 'No album with this name on the device. Nothing is being sent.',
                  style: text.bodySmall?.copyWith(color: Palette.warn),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy ? null : _editAlbums,
                child: Text(
                  'More albums: ${status.moreAlbums.length}, never sent: ${status.excludedAlbums.length}',
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: Text('Only on Wi-Fi', style: text.bodyMedium)),
                Switch(
                  value: status.wifiOnly,
                  activeTrackColor: Palette.gold,
                  onChanged: (value) async {
                    await ref.read(backupProvider).setWifiOnly(value);
                    await _refresh();
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Only while charging', style: text.bodyMedium),
                ),
                Switch(
                  value: status.chargingOnly,
                  activeTrackColor: Palette.gold,
                  onChanged: (value) async {
                    await ref.read(backupProvider).setChargingOnly(value);
                    await _refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${status.verified} of ${status.total} verified on the server',
              style: text.bodyLarge,
            ),
            if (status.total > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: LinearProgressIndicator(
                  value: status.verified / status.total,
                  minHeight: 4,
                  color: Palette.gold,
                  backgroundColor: Palette.bg3,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${status.working} sending · ${status.pending} waiting · ${status.failed} failed',
              style: text.bodySmall,
            ),
            Text(
              describeLastBackup(status.lastFinished, DateTime.now()),
              style: text.bodySmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BackupDevicesScreen(),
                  ),
                ),
                child: const Text('What the server confirms, per device'),
              ),
            ),
            if (status.unauthorized)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'The server refused this device. Turn backup off and on again.',
                  style: text.bodySmall?.copyWith(color: Palette.err),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                label: const Text('Free up space'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FreeSpaceScreen(),
                  ),
                ),
              ),
            ),
            if (status.failed > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(backupProvider).retryFailed();
                    await _refresh();
                  },
                  child: Text('Try the ${status.failed} failed again'),
                ),
              ),
            if (status.failures.isNotEmpty)
              Text(
                status.failures.first.error,
                style: text.bodySmall?.copyWith(color: Palette.err),
              ),
          ] else
            Text(
              'Sends one album of your choice, and nothing else. Checks for new photos every minute '
              'while the app is open. When it is closed, iOS decides when, often much later, and '
              'stops it if you swipe the app away.',
              style: text.bodySmall,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: text.bodySmall?.copyWith(color: Palette.err),
              ),
            ),
        ],
      ),
    );
  }
}

class AlbumChoice {
  AlbumChoice({required this.id, required this.name});

  final String? id;
  final String name;
}

/// Lists the device's albums, and also takes a typed name for an album that may not exist yet.
class AlbumPicker extends StatefulWidget {
  const AlbumPicker({super.key, required this.albums});

  final List<BackupAlbum> albums;

  @override
  State<AlbumPicker> createState() => _AlbumPickerState();
}

class _AlbumPickerState extends State<AlbumPicker> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final typed = _name.text.trim();
    final matches = widget.albums
        .where(
          (album) => album.title.toLowerCase().contains(typed.toLowerCase()),
        )
        .toList();
    final exact = matches.any(
      (album) => album.title.toLowerCase() == typed.toLowerCase(),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text('Which album?', style: text.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _name,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Album name'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView(
                  children: [
                    if (typed.isNotEmpty && !exact)
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text('Use the name "$typed"'),
                        subtitle: const Text(
                          'Starts when an album with this name exists',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          AlbumChoice(id: null, name: typed),
                        ),
                      ),
                    for (final album in matches)
                      ListTile(
                        leading: const Icon(Icons.photo_album_outlined),
                        title: Text(album.title),
                        trailing: Text('${album.count}', style: text.bodySmall),
                        onTap: () => Navigator.pop(
                          context,
                          AlbumChoice(id: album.id, name: album.title),
                        ),
                      ),
                    if (widget.albums.isEmpty && typed.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No albums on this device yet. Create one in Photos.',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlbumLists {
  const AlbumLists(this.more, this.excluded);

  final List<String> more;
  final List<String> excluded;
}

enum AlbumRole { none, send, never }

/// An album is either sent, never sent, or left alone.
AlbumLists albumListsFrom(Map<String, AlbumRole> roles) => AlbumLists(
  [
    for (final entry in roles.entries)
      if (entry.value == AlbumRole.send) entry.key,
  ],
  [
    for (final entry in roles.entries)
      if (entry.value == AlbumRole.never) entry.key,
  ],
);

class AlbumListsSheet extends StatefulWidget {
  const AlbumListsSheet({
    super.key,
    required this.albums,
    required this.more,
    required this.excluded,
  });

  final List<BackupAlbum> albums;
  final List<String> more;
  final List<String> excluded;

  @override
  State<AlbumListsSheet> createState() => _AlbumListsSheetState();
}

class _AlbumListsSheetState extends State<AlbumListsSheet> {
  late final Map<String, AlbumRole> _roles = {
    for (final id in widget.more) id: AlbumRole.send,
    for (final id in widget.excluded) id: AlbumRole.never,
  };

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'A photo in a "Never" album is not sent, even if it is also in another album.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final album in widget.albums)
                  ListTile(
                    title: Text(album.title),
                    subtitle: Text('${album.count}'),
                    trailing: DropdownButton<AlbumRole>(
                      value: _roles[album.id] ?? AlbumRole.none,
                      items: const [
                        DropdownMenuItem(
                          value: AlbumRole.none,
                          child: Text('Not added'),
                        ),
                        DropdownMenuItem(
                          value: AlbumRole.send,
                          child: Text('Back up'),
                        ),
                        DropdownMenuItem(
                          value: AlbumRole.never,
                          child: Text('Never'),
                        ),
                      ],
                      onChanged: (role) => setState(
                        () => _roles[album.id] = role ?? AlbumRole.none,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GoldButton(
              label: 'Save',
              onPressed: () => Navigator.pop(context, albumListsFrom(_roles)),
            ),
          ),
        ],
      ),
    ),
  );
}
