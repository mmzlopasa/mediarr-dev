import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';
import 'album_screen.dart';
import 'devices_screen.dart';
import '../l10n/l10n.dart';

/// Null when the server has no answer, as an older server does not. The app can be newer than the
/// server it talks to, and that must not get in the way of anything else on the screen.
Future<NotificationList?> _fetchNotifications(DefaultApi api) async {
  final response = await api.listNotificationsWithHttpInfo();
  if (response.statusCode >= 400 || response.body.isEmpty) return null;
  return NotificationList.fromJson(jsonDecode(response.body));
}

/// The sentence for a notification. The server says only what happened.
String notificationSentence(Notification item) {
  final kind = item.kind;
  if (kind == NotificationKindEnum.albumShared) {
    return l.notificationsAlbumShared(item.subject);
  }
  if (kind == NotificationKindEnum.importDone) {
    return l.notificationsImportDone(item.subject);
  }
  if (kind == NotificationKindEnum.importFailed) {
    return l.notificationsImportFailed(item.subject);
  }
  if (kind == NotificationKindEnum.deviceQuiet) {
    return l.notificationsDeviceQuiet(item.subject);
  }
  if (kind == NotificationKindEnum.backupLate) {
    // "to:<name>" is our copy at another Mediarr; "from:<name>" is one kept here.
    final at = item.subject.indexOf(':');
    final name = item.subject.substring(at + 1);
    return item.subject.startsWith('to:')
        ? l.notificationsCopyForLate(name)
        : l.notificationsCopyFromLate(name);
  }
  return l.notificationsBackupFailed(item.subject);
}

/// The bell in the header, with how many are new.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  static const _refreshEvery = Duration(minutes: 1);

  Timer? _timer;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(_refreshEvery, (_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      final list = await _fetchNotifications(session.api);
      if (mounted && list != null) setState(() => _unread = list.unread);
    } on ApiException {
      // The count stays as it was until the server answers again.
    }
  }

  Future<void> _open() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 40, 10, 10),
          child: GlassCard(radius: 28, child: NotificationsSheet()),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: l.notificationsTitle,
    onPressed: _open,
    icon: Badge(
      isLabelVisible: _unread > 0,
      backgroundColor: Palette.buttonGold,
      textColor: Palette.onGold,
      label: Text(_unread > 99 ? '99+' : '$_unread'),
      child: const Icon(Icons.notifications_none),
    ),
  );
}

/// The list. Opening it marks everything as read.
class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  List<Notification>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      final list = await _fetchNotifications(session.api);
      if (!mounted) return;
      if (list == null) {
        setState(() => _failed = true);
        return;
      }
      setState(() {
        _items = list.items;
        _failed = false;
      });
      if (list.unread > 0) await session.api.readNotifications();
    } on ApiException {
      if (mounted && _items == null) setState(() => _failed = true);
    }
  }

  Future<void> _remove(Notification item) async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    try {
      await session.api.deleteNotification(item.id);
      if (mounted) setState(() => _items?.remove(item));
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.notificationsNotRemoved)));
      }
    }
  }

  void _openDevices() {
    final navigator = Navigator.of(context)..pop();
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const BackupDevicesScreen()),
      ),
    );
  }

  void _openAlbum(Notification item) {
    final navigator = Navigator.of(context)..pop();
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => AlbumScreen(albumId: item.ref, title: item.subject),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final text = Theme.of(context).textTheme;
    final Widget body;
    if (_failed) {
      body = Text(l.notificationsNotLoaded);
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      body = Text(l.notificationsNone);
    } else {
      body = ListView(
        shrinkWrap: true,
        children: [
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                notificationSentence(item),
                style: item.read
                    ? null
                    : const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(item.createdAt.toLocal()),
              ),
              onTap: switch (item.kind) {
                NotificationKindEnum.albumShared when item.ref.isNotEmpty =>
                  () => _openAlbum(item),
                NotificationKindEnum.deviceQuiet => _openDevices,
                _ => null,
              },
              trailing: IconButton(
                tooltip: l.notificationsRemove,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _remove(item),
              ),
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.notificationsTitle, style: text.titleLarge),
          const SizedBox(height: 12),
          Flexible(child: body),
        ],
      ),
    );
  }
}
