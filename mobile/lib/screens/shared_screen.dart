import '../services/days.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'album_screen.dart';
import 'timeline_screen.dart';
import 'viewer_screen.dart';

/// Albums and libraries shared with this user, and who sees this user's library.
class SharedScreen extends ConsumerStatefulWidget {
  const SharedScreen({super.key});

  @override
  ConsumerState<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends ConsumerState<SharedScreen> {
  List<Album>? _albums;
  Partners? _partners;
  List<UserRef> _users = const [];
  bool _failed = false;
  String? _userId;
  DateTime? _since;
  Timer? _poll;

  Session? get _session => ref.read(sessionProvider).value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final session = _session;
    if (session == null) return;
    try {
      final albums = await session.api.listAlbums();
      final partners = await session.api.listPartners();
      final users = await session.api.listDirectory();
      if (!mounted) return;
      setState(() {
        _albums = albums ?? const [];
        _partners = partners;
        _users = users ?? const [];
        _failed = false;
      });
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } on ApiException catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.sharedScreenActionFailed(cause.message ?? '')),
          ),
        );
      }
    }
  }

  String _sinceLabel(DateTime? since) => since == null
      ? l.sharedScreenWholeLibrary
      : l.sharedScreenFrom(
          '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}',
        );

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final text = Theme.of(context).textTheme;
    final partners = _partners;
    final albums = _albums;
    if (session == null) return const SizedBox.shrink();

    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Text(label, style: text.titleMedium),
    );
    Widget none(String label) =>
        Text(label, style: text.bodyMedium?.copyWith(color: Palette.dim));

    Widget body;
    if (albums == null || partners == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: l.sharedScreenLoadFailed,
              action: GoldButton(
                label: l.sharedScreenTryAgain,
                onPressed: _load,
              ),
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else {
      final withMe = albums
          .where((album) => album.role != AlbumRoleEnum.owner)
          .toList();
      final free = _users
          .where(
            (user) => !partners.given.any((entry) => entry.userId == user.id),
          )
          .toList();
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          heading(l.sharedScreenAlbumsWithMe),
          if (withMe.isEmpty) none(l.sharedScreenNothingShared),
          for (final album in withMe)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_album_outlined),
              title: Text(album.title),
              subtitle: Text('${album.ownerName} · ${album.assetCount}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AlbumScreen(albumId: album.id, title: album.title),
                ),
              ),
            ),
          heading(l.sharedScreenLibrariesWithMe),
          if (partners.received.isEmpty) none(l.sharedScreenNobodyShares),
          for (final entry in partners.received)
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(entry.name),
                  subtitle: Text(_sinceLabel(entry.since)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _PartnerLibrary(entry: entry),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.sharedScreenShowInMyMedia),
                  value: entry.inTimeline,
                  onChanged: (value) => _run(
                    () => session.api.setPartnerTimeline(
                      entry.userId,
                      PartnerTimeline(show_: value),
                    ),
                  ),
                ),
              ],
            ),
          heading(l.sharedScreenMyLibrarySharedWith),
          if (partners.given.isEmpty) none(l.sharedScreenNobodyYet),
          for (final entry in partners.given)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.name),
              subtitle: Text(_sinceLabel(entry.since)),
              trailing: TextButton(
                onPressed: () =>
                    _run(() => session.api.removePartner(entry.userId)),
                child: Text(l.sharedScreenStop),
              ),
            ),
          if (free.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _userId,
              decoration: InputDecoration(labelText: l.sharedScreenUser),
              items: [
                for (final user in free)
                  DropdownMenuItem(value: user.id, child: Text(user.name)),
              ],
              onChanged: (value) => setState(() => _userId = value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_sinceLabel(_since)),
              trailing: TextButton(
                child: Text(l.sharedScreenChooseDate),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _since = picked);
                },
              ),
            ),
            none(l.sharedScreenNeverShared),
            const SizedBox(height: 10),
            GoldButton(
              label: l.sharedScreenShareMyLibrary,
              onPressed: () {
                final user = _userId;
                if (user == null) return;
                _run(() async {
                  await session.api.setPartner(
                    user,
                    PartnerShare(
                      since: _since == null ? null : dayOnly(_since!),
                    ),
                  );
                  _userId = null;
                  _since = null;
                });
              },
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.sharedScreenShared)),
      body: body,
    );
  }
}

class _PartnerLibrary extends ConsumerStatefulWidget {
  const _PartnerLibrary({required this.entry});

  final PartnerEntry entry;

  @override
  ConsumerState<_PartnerLibrary> createState() => _PartnerLibraryState();
}

class _PartnerLibraryState extends ConsumerState<_PartnerLibrary> {
  late final Session _session = ref.read(sessionProvider).value!;
  late final TimelineStore _store = TimelineStore.partner(
    _session,
    widget.entry.userId,
  );
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _store.refresh();
    _poll = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _store.refresh(),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.entry.name)),
    body: ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final months = _store.months;
        if (months == null) {
          return _store.failed
              ? EmptyMessage(
                  icon: Icons.lock_outline,
                  text: l.sharedScreenLibraryNotAvailable,
                )
              : Center(child: CircularProgressIndicator(color: Palette.gold));
        }
        if (months.isEmpty) {
          return EmptyMessage(
            icon: Icons.photo_outlined,
            text: l.sharedScreenNoPhotos,
          );
        }
        return TimelineGrid(
          store: _store,
          session: _session,
          selected: const {},
          onToggle: (_) {},
          onOpen: (index) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ViewerScreen(initialIndex: index, store: _store),
            ),
          ),
        );
      },
    ),
  );
}
