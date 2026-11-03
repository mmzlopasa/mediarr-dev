import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

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
          SnackBar(content: Text('The action failed. ${cause.message ?? ''}')),
        );
      }
    }
  }

  String _sinceLabel(DateTime? since) => since == null
      ? 'Whole library'
      : 'From ${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';

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
              text: 'This could not be loaded. Check the connection.',
              action: GoldButton(label: 'Try again', onPressed: _load),
            )
          : const Center(child: CircularProgressIndicator(color: Palette.gold));
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
          heading('Albums shared with me'),
          if (withMe.isEmpty) none('Nothing has been shared yet.'),
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
          heading('Libraries shared with me'),
          if (partners.received.isEmpty)
            none('Nobody shares their library with you.'),
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
                  title: const Text('Show in my Media'),
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
          heading('My library is shared with'),
          if (partners.given.isEmpty) none('Nobody yet.'),
          for (final entry in partners.given)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.name),
              subtitle: Text(_sinceLabel(entry.since)),
              trailing: TextButton(
                onPressed: () =>
                    _run(() => session.api.removePartner(entry.userId)),
                child: const Text('Stop'),
              ),
            ),
          if (free.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _userId,
              decoration: const InputDecoration(labelText: 'User'),
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
                child: const Text('Choose date'),
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
            none('The archive, trash and vault are never shared.'),
            const SizedBox(height: 10),
            GoldButton(
              label: 'Share my library',
              onPressed: () {
                final user = _userId;
                if (user == null) return;
                _run(() async {
                  await session.api.setPartner(
                    user,
                    PartnerShare(since: _since),
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
      appBar: AppBar(title: const Text('Shared')),
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
              ? const EmptyMessage(
                  icon: Icons.lock_outline,
                  text: 'This library is not available.',
                )
              : const Center(
                  child: CircularProgressIndicator(color: Palette.gold),
                );
        }
        if (months.isEmpty) {
          return const EmptyMessage(
            icon: Icons.photo_outlined,
            text: 'No photos yet.',
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
