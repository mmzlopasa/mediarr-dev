import '../services/days.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mediarr_api/api.dart';

import '../services/account_preferences.dart';
import '../services/session.dart';
import '../services/trash.dart';
import '../services/settings.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'share_sheet.dart';
import '../timeline/layout.dart';
import 'album_sheets.dart';
import 'api_keys_screen.dart';
import 'map_screen.dart';
import 'documents_screen.dart';
import 'duplicates_screen.dart';
import 'folders_screen.dart';
import 'memories_screen.dart';
import 'people_screens.dart';
import 'timeline_screen.dart';
import 'viewer_screen.dart';

const _vaultPinKey = 'vault_pin';
const _storage = FlutterSecureStorage();

/// The PIN kept for Face ID must not outlive the sign-in.
Future<void> forgetVaultPin() async {
  try {
    await _storage.delete(key: _vaultPinKey);
  } on PlatformException {
    // Nothing was kept.
  } on MissingPluginException {
    // No secure storage on this platform.
  }
}

/// The places in the library, as tiles in two columns, like the web's More. Sections the person
/// took off the menu stay off here too.
class OrganizeLinks extends ConsumerWidget {
  const OrganizeLinks({super.key, this.leading = const []});

  /// Places shown before the organising ones (Explore, Shared).
  final List<(IconData, String, Widget)> leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readOnly = ref.watch(settingsProvider).readOnly;
    final hidden =
        ref.watch(accountPreferencesProvider).value?.hiddenSections ??
        const <String>[];
    final places = <(IconData, String, Widget)>[
      ...leading,
      if (!hidden.contains('/favorites'))
        (Icons.star_outline, 'Favorites', const FavoritesScreen()),
      if (!hidden.contains('/memories'))
        (Icons.auto_awesome_outlined, 'Memories', const MemoriesScreen()),
      if (!hidden.contains('/people'))
        (Icons.people_outline, 'People', const PeopleScreen()),
      if (!hidden.contains('/map'))
        (Icons.map_outlined, 'Map', const MapScreen()),
      if (!hidden.contains('/folders'))
        (Icons.folder_outlined, 'Folders', const FoldersScreen()),
      if (!hidden.contains('/family'))
        (Icons.family_restroom, 'Family', const FamilyScreen()),
      if (!hidden.contains('/documents'))
        (Icons.description_outlined, 'Documents', const DocumentsScreen()),
      if (!readOnly && !hidden.contains('/duplicates'))
        (Icons.copy_all_outlined, 'Duplicates', const DuplicatesScreen()),
      if (!readOnly) (Icons.archive_outlined, 'Archive', const ArchiveScreen()),
      if (!readOnly) (Icons.delete_outline, 'Trash', const TrashScreen()),
      if (!readOnly) (Icons.lock_outline, 'Vault', const VaultScreen()),
      (Icons.key_outlined, 'API keys', const ApiKeysScreen()),
      (Icons.sell_outlined, 'Tags', const TagsScreen()),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 60,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final (icon, label, screen) = places[index];
        return Material(
          color: Palette.bg2,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => screen)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Palette.dim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter Tight',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A grid of photos with selection, for any place that is not the main timeline.
class _PhotoGrid extends StatefulWidget {
  const _PhotoGrid({
    required this.store,
    required this.session,
    required this.emptyText,
    required this.actions,
    this.readOnly = true,
    this.onUnauthorized,
  });

  final TimelineStore store;
  final Session session;
  final String emptyText;
  final List<Widget> Function(Set<String> selected, VoidCallback clear) actions;
  final bool readOnly;
  final VoidCallback? onUnauthorized;

  @override
  State<_PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<_PhotoGrid> {
  final _selected = <String>{};
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    widget.store.refresh();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      widget.store.refresh();
    });
    widget.store.addListener(_watch);
  }

  void _watch() {
    if (widget.store.failed) widget.onUnauthorized?.call();
  }

  @override
  void dispose() {
    _poll?.cancel();
    widget.store.removeListener(_watch);
    super.dispose();
  }

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final months = widget.store.months;
      if (months == null) {
        return widget.store.failed
            ? const EmptyMessage(
                icon: Icons.cloud_off,
                text: 'This could not be loaded. Check the connection.',
              )
            : Center(child: CircularProgressIndicator(color: Palette.gold));
      }
      if (months.isEmpty) {
        return EmptyMessage(icon: Icons.photo_outlined, text: widget.emptyText);
      }
      return Column(
        children: [
          if (_selected.isNotEmpty)
            Row(
              children: [
                IconButton(
                  tooltip: 'Clear selection',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_selected.clear),
                ),
                Text('${_selected.length}'),
                const Spacer(),
                Consumer(
                  builder: (context, ref, _) => IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => shareAssets(
                      context,
                      ref,
                      widget.session,
                      _selected.toList(),
                    ),
                  ),
                ),
                ...widget.actions(_selected, () => setState(_selected.clear)),
              ],
            ),
          Expanded(
            child: TimelineGrid(
              store: widget.store,
              session: widget.session,
              selected: _selected,
              onToggle: _toggle,
              onOpen: (index) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ViewerScreen(
                    initialIndex: index,
                    store: widget.store,
                    session: widget.session,
                    readOnly: widget.readOnly,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<bool> _confirmPermanent(
  BuildContext context,
  String title, {
  String? detail,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(
        [
          ?detail,
          'The originals are removed from the disk. This cannot be undone.',
        ].join(' '),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete permanently',
            style: TextStyle(color: Palette.err),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}

void _tell(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// Runs one bulk action on the selection and says how it went.
Future<void> _bulk(
  BuildContext context,
  CollectionSession session,
  TimelineStore store,
  Set<String> selected,
  VoidCallback clear,
  BulkRequestActionEnum action,
  String done,
) async {
  try {
    final result = await session.api.bulkAssets(
      BulkRequest(ids: selected.toList(), action: action),
    );
    clear();
    await store.refresh(reloadLoaded: true);
    if (context.mounted) {
      _tell(context, '$done: ${result?.changed ?? 0}');
    }
  } on ApiException catch (cause) {
    if (context.mounted) {
      _tell(context, 'The action failed. ${cause.message ?? ''}');
    }
  }
}

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  late final _session = CollectionSession(
    ref.read(sessionProvider).value!,
    'favorites',
  );
  late final _store = TimelineStore.collection(_session);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favorites')),
    body: _PhotoGrid(
      store: _store,
      session: _session,
      emptyText: 'No favorites yet. Mark a photo with the star.',
      actions: (selected, clear) => [
        IconButton(
          tooltip: 'Remove from favorites',
          icon: const Icon(Icons.star_outline),
          onPressed: () => _bulk(
            context,
            _session,
            _store,
            selected,
            clear,
            BulkRequestActionEnum.unfavorite,
            'Removed from favorites',
          ),
        ),
      ],
    ),
  );
}

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  late final _session = CollectionSession(
    ref.read(sessionProvider).value!,
    'archive',
  );
  late final _store = TimelineStore.collection(_session);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Archive')),
    body: _PhotoGrid(
      store: _store,
      session: _session,
      emptyText: 'The archive is empty.',
      actions: (selected, clear) => [
        IconButton(
          tooltip: 'Back to Media',
          icon: const Icon(Icons.unarchive_outlined),
          onPressed: () => _bulk(
            context,
            _session,
            _store,
            selected,
            clear,
            BulkRequestActionEnum.unarchive,
            'Back in Media',
          ),
        ),
      ],
    ),
  );
}

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  late final _session = CollectionSession(
    ref.read(sessionProvider).value!,
    'trash',
  );
  late final _store = TimelineStore.collection(_session);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _empty() async {
    // What it would remove is shown before anything is decided.
    String? detail;
    try {
      final summary = await _session.api.getTrashSummary();
      if (summary != null) {
        detail =
            'This removes ${summary.assets} files, ${formatBytes(summary.bytes)}.';
      }
    } on ApiException {
      // The question can still be asked without the numbers.
    }
    if (!mounted) return;
    if (!await _confirmPermanent(context, 'Empty the trash?', detail: detail)) {
      return;
    }
    try {
      final result = await _session.api.emptyTrash();
      await _store.refresh(reloadLoaded: true);
      if (mounted) {
        _tell(context, 'Permanently deleted: ${result?.changed ?? 0}');
      }
    } on ApiException catch (cause) {
      if (mounted) _tell(context, 'The action failed. ${cause.message ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trash'),
      actions: [TextButton(onPressed: _empty, child: const Text('Empty'))],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TrashSentence(
            (days) => days == null
                ? 'Items here are deleted permanently after a while.'
                : 'Items are permanently deleted after $days days.',
          ),
        ),
        Expanded(
          child: _PhotoGrid(
            store: _store,
            session: _session,
            emptyText: 'The trash is empty.',
            actions: (selected, clear) => [
              IconButton(
                tooltip: 'Restore',
                icon: const Icon(Icons.restore),
                onPressed: () => _bulk(
                  context,
                  _session,
                  _store,
                  selected,
                  clear,
                  BulkRequestActionEnum.restore,
                  'Restored',
                ),
              ),
              IconButton(
                tooltip: 'Delete permanently',
                icon: const Icon(Icons.delete_forever_outlined),
                onPressed: () async {
                  if (!await _confirmPermanent(
                    context,
                    'Delete permanently?',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  await _bulk(
                    context,
                    _session,
                    _store,
                    selected,
                    clear,
                    BulkRequestActionEnum.purge,
                    'Permanently deleted',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Asks for the PIN or Face ID, shows the vault, and locks it again on leaving.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _pin = TextEditingController();
  final _biometrics = LocalAuthentication();
  late final Session _session = ref.read(sessionProvider).value!;
  VaultStatus? _status;
  bool _failed = false;
  String? _error;
  bool _busy = false;
  bool _canUseBiometrics = false;
  bool _useBiometrics = true;
  CollectionSession? _open;
  TimelineStore? _store;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    _store?.dispose();
    if (_open != null) {
      // Leaving locks it, also for a token that was not used up.
      unawaited(_session.api.lockVault().catchError((Object _) {}));
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await _session.api.getVaultStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _failed = false;
      });
      await _prepareBiometrics();
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _prepareBiometrics() async {
    try {
      final supported = await _biometrics.isDeviceSupported();
      if (!mounted) return;
      setState(() => _canUseBiometrics = supported);
      final saved = await _storage.read(key: _vaultPinKey);
      if (!supported || saved == null || _status?.hasPin != true) return;
      final passed = await _biometrics.authenticate(
        localizedReason: 'Open your vault',
      );
      if (passed) await _unlock(saved, keep: false);
    } on PlatformException {
      // Face ID is off or was cancelled, and the PIN still works.
    } on MissingPluginException {
      // No biometrics on this platform.
    } on LocalAuthException {
      // The same: the PIN still works.
    }
  }

  Future<void> _unlock(String pin, {required bool keep}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _session.api.unlockVault(VaultUnlock(pin: pin));
      if (keep && _canUseBiometrics && _useBiometrics) {
        await _storage.write(key: _vaultPinKey, value: pin);
      }
      if (!mounted || session == null) return;
      final open = CollectionSession(
        _session,
        'vault',
        vaultToken: session.token,
      );
      setState(() {
        _open = open;
        _store = TimelineStore.collection(open);
        _pin.clear();
      });
    } on ApiException catch (cause) {
      if (cause.code == 401) await forgetVaultPin();
      if (mounted) {
        setState(() {
          _error = cause.code == 429
              ? 'Too many attempts. Try again later.'
              : 'Wrong PIN.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final pin = _pin.text;
    if (_status?.hasPin == true) {
      await _unlock(pin, keep: true);
      return;
    }
    try {
      await _session.api.setVaultPin(VaultPinChange(pin: pin));
      // A PIN kept from before no longer opens anything.
      await forgetVaultPin();
      if (mounted) {
        setState(() => _status = VaultStatus(hasPin: true, unlocked: false));
      }
      await _unlock(pin, keep: true);
    } on ApiException {
      if (mounted) {
        setState(() => _error = 'The PIN must have between 4 and 12 digits.');
      }
    }
  }

  /// The session ended on the server, so nothing more is shown.
  void _relock() {
    if (_open == null) return;
    setState(() {
      _store?.dispose();
      _store = null;
      _open = null;
      _error = 'The vault locked itself. Unlock it again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    final store = _store;
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: open != null && store != null
          ? _PhotoGrid(
              store: store,
              session: open,
              emptyText: 'The vault is empty.',
              onUnauthorized: _relock,
              actions: (selected, clear) => [
                IconButton(
                  tooltip: 'Back to Media',
                  icon: const Icon(Icons.photo_outlined),
                  onPressed: () => _bulk(
                    context,
                    open,
                    store,
                    selected,
                    clear,
                    BulkRequestActionEnum.unvault,
                    'Back in Media',
                  ),
                ),
                IconButton(
                  tooltip: 'Delete permanently',
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () async {
                    if (!await _confirmPermanent(
                      context,
                      'Delete permanently?',
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    await _bulk(
                      context,
                      open,
                      store,
                      selected,
                      clear,
                      BulkRequestActionEnum.purge,
                      'Permanently deleted',
                    );
                  },
                ),
              ],
            )
          : _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: 'The vault could not be loaded. Check the connection.',
              action: GoldButton(label: 'Try again', onPressed: _load),
            )
          : status == null
          ? Center(child: CircularProgressIndicator(color: Palette.gold))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Hidden from every other view and from sharing. '
                  'The files on the server are not encrypted.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: status.hasPin ? 'PIN' : 'New PIN',
                    helperText: status.hasPin ? null : 'From 4 to 12 digits. Only the server administrator can reset a lost PIN.',
                    helperMaxLines: 2,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: TextStyle(color: Palette.err)),
                  ),
                if (_canUseBiometrics)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use Face ID next time'),
                    value: _useBiometrics,
                    onChanged: (value) =>
                        setState(() => _useBiometrics = value),
                  ),
                const SizedBox(height: 12),
                GoldButton(
                  label: status.hasPin ? 'Unlock' : 'Set PIN',
                  onPressed: _busy ? () {} : _submit,
                ),
              ],
            ),
    );
  }
}

/// Adds a tag to the selected photos: an existing one, or a new one.
Future<bool> showAddTag(
  BuildContext context,
  Session session,
  List<String> ids,
) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddTagSheet(session: session, ids: ids),
  );
  return done == true;
}

class _AddTagSheet extends StatefulWidget {
  const _AddTagSheet({required this.session, required this.ids});

  final Session session;
  final List<String> ids;

  @override
  State<_AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<_AddTagSheet> {
  final _name = TextEditingController();
  List<Tag> _tags = const [];

  @override
  void initState() {
    super.initState();
    widget.session.api.listTags().then((tags) {
      if (mounted) setState(() => _tags = tags ?? const []);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add(String name) async {
    if (name.trim().isEmpty) return;
    final navigator = Navigator.of(context);
    try {
      await widget.session.api.changeAssetTags(
        AssetTagChange(ids: widget.ids, name: name),
      );
      navigator.pop(true);
    } on ApiException catch (cause) {
      if (mounted) _tell(context, 'The action failed. ${cause.message ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: 'Add a tag',
    children: [
      for (final tag in _tags)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tag.name),
          trailing: Text('${tag.assetCount}'),
          onTap: () => _add(tag.name),
        ),
      TextField(
        controller: _name,
        maxLength: 100,
        decoration: const InputDecoration(labelText: 'New tag'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _add(_name.text),
          child: const Text('Create and add'),
        ),
      ),
    ],
  );
}

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<Tag>? _tags;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tags = await _session.api.listTags();
      if (mounted) {
        setState(() {
          _tags = tags ?? const [];
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: tags == null
          ? _failed
                ? const EmptyMessage(
                    icon: Icons.cloud_off,
                    text: 'Tags could not be loaded.',
                  )
                : Center(child: CircularProgressIndicator(color: Palette.gold))
          : tags.isEmpty
          ? const EmptyMessage(
              icon: Icons.sell_outlined,
              text: 'No tags yet. Select photos and add a tag.',
            )
          : ListView(
              children: [
                for (final tag in tags)
                  ListTile(
                    title: Text(tag.name),
                    subtitle: Text('${tag.assetCount}'),
                    trailing: IconButton(
                      tooltip: 'Delete tag',
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        try {
                          await _session.api.deleteTag(tag.id);
                          await _load();
                        } on ApiException catch (cause) {
                          if (context.mounted) {
                            _tell(
                              context,
                              'The action failed. ${cause.message ?? ''}',
                            );
                          }
                        }
                      },
                    ),
                    onTap: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute<void>(
                            builder: (_) => _TagScreen(tag: tag),
                          ),
                        )
                        .then((_) => _load()),
                  ),
              ],
            ),
    );
  }
}

class _TagScreen extends ConsumerStatefulWidget {
  const _TagScreen({required this.tag});

  final Tag tag;

  @override
  ConsumerState<_TagScreen> createState() => _TagScreenState();
}

class _TagScreenState extends ConsumerState<_TagScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  late final _store = TimelineStore.tag(_session, widget.tag.id);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.tag.name)),
    body: _PhotoGrid(
      store: _store,
      session: _session,
      emptyText: 'No photos carry this tag.',
      readOnly: false,
      actions: (selected, clear) => [
        IconButton(
          tooltip: 'Remove the tag',
          icon: const Icon(Icons.label_off_outlined),
          onPressed: () async {
            try {
              await _session.api.changeAssetTags(
                AssetTagChange(
                  ids: selected.toList(),
                  name: widget.tag.name,
                  remove: true,
                ),
              );
              clear();
              await _store.refresh(reloadLoaded: true);
            } on ApiException catch (cause) {
              if (context.mounted) {
                _tell(context, 'The action failed. ${cause.message ?? ''}');
              }
            }
          },
        ),
      ],
    ),
  );
}

/// Why there is nothing to show, for someone who cannot see the family library.
String? familyClosedText(Family family) {
  if (!family.enabled) return 'An administrator has not turned this on.';
  if (!family.member) return 'You are not in the family library yet.';
  return null;
}

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  late final _store = TimelineStore.family(_session);
  Family? _family;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final family = await _session.api.getFamily();
      if (!mounted) return;
      setState(() {
        _family = family;
        _failed = false;
      });
      if (family != null && familyClosedText(family) == null) {
        await _store.refresh(reloadLoaded: true);
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _rules() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => _FamilyRulesScreen(family: _family!),
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final family = _family;
    final closed = family == null ? null : familyClosedText(family);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        actions: [
          if (family != null && closed == null)
            IconButton(
              tooltip: 'What I share',
              icon: const Icon(Icons.tune),
              onPressed: _rules,
            ),
        ],
      ),
      body: family == null
          ? _failed
                ? const EmptyMessage(
                    icon: Icons.cloud_off,
                    text: 'The family library could not be loaded.',
                  )
                : Center(child: CircularProgressIndicator(color: Palette.gold))
          : closed != null
          ? EmptyMessage(icon: Icons.family_restroom, text: closed)
          : _PhotoGrid(
              store: _store,
              session: _session,
              emptyText: 'Nobody has shared anything with the family yet.',
              actions: (selected, clear) => const [],
            ),
    );
  }
}

class _FamilyRulesScreen extends ConsumerStatefulWidget {
  const _FamilyRulesScreen({required this.family});

  final Family family;

  @override
  ConsumerState<_FamilyRulesScreen> createState() => _FamilyRulesScreenState();
}

class _FamilyRulesScreenState extends ConsumerState<_FamilyRulesScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  late List<FamilyRule> _rules = widget.family.rules;

  Future<void> _reload() async {
    final family = await _session.api.getFamily();
    if (mounted && family != null) setState(() => _rules = family.rules);
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final from = TextEditingController();
    final place = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share with the family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Rule name'),
            ),
            TextField(
              controller: from,
              decoration: const InputDecoration(
                labelText: 'From date (2024-06-01)',
              ),
            ),
            TextField(
              controller: place,
              decoration: const InputDecoration(labelText: 'Place'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    final name = title.text.trim();
    final since = DateTime.tryParse(from.text.trim());
    final where = place.text.trim();
    title.dispose();
    from.dispose();
    place.dispose();
    if (confirmed != true) return;
    try {
      await _session.api.createFamilyRule(
        FamilyRuleCreate(
          title: name,
          rules: AlbumRules(
            from: since == null ? null : dayOnly(since),
            place: where.isEmpty ? null : where,
          ),
        ),
      );
      await _reload();
    } on ApiException catch (cause) {
      if (mounted) _tell(context, 'It was not saved. ${cause.message ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('What I share'),
      actions: [
        IconButton(
          tooltip: 'New rule',
          icon: const Icon(Icons.add),
          onPressed: _add,
        ),
      ],
    ),
    body: _rules.isEmpty
        ? const EmptyMessage(
            icon: Icons.family_restroom,
            text: 'You share nothing with the family yet.',
          )
        : ListView(
            children: [
              for (final rule in _rules)
                ListTile(
                  title: Text(rule.title),
                  trailing: IconButton(
                    tooltip: 'Stop sharing',
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      try {
                        await _session.api.deleteFamilyRule(rule.id);
                        await _reload();
                      } on ApiException {
                        if (context.mounted) {
                          _tell(context, 'The action failed.');
                        }
                      }
                    },
                  ),
                ),
            ],
          ),
  );
}
