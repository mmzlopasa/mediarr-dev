import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

/// What a role allows. The server decides; this only hides what would be refused.
class AlbumRights {
  AlbumRights(this.role, {required this.isSmart});

  final AlbumRoleEnum role;
  final bool isSmart;

  bool get isOwner => role == AlbumRoleEnum.owner;
  bool get canEdit => isOwner || role == AlbumRoleEnum.editor;
  bool get canAdd => !isSmart && role != AlbumRoleEnum.viewer;
}

/// Built from the address the app is connected to: an IP address works as well as a domain.
String publicLinkUrl(String serverUrl, String token) => '$serverUrl/s/$token';

String roleLabel(Object? role) => switch (role?.toString()) {
  'owner' => 'Owner',
  'editor' => 'Editor',
  'contributor' => 'Contributor',
  _ => 'Viewer',
};

String linkSummary(ShareLink link) => [
  if (link.uploadOnly) 'upload only',
  if (link.hasPassword) 'password',
  if (link.watermark != null) 'watermark',
  if (link.expiresAt != null) 'expires ${_day(link.expiresAt!)}',
  if (!link.uploadOnly)
    'downloads: ${link.downloadCount}'
        '${link.downloadLimit != null ? ' / ${link.downloadLimit}' : ''}',
].join(' · ');

String _day(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

void _failed(BuildContext context, [Object? cause]) {
  final detail = cause is ApiException ? cause.message : null;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text('The action failed.${detail != null ? ' $detail' : ''}'),
    ),
  );
}

class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// Comments on an album or a photo, and that photo's hearts. Refreshes while open.
class ActivitySheet extends StatefulWidget {
  const ActivitySheet({
    super.key,
    required this.session,
    required this.albumId,
    this.assetId,
  });

  final Session session;
  final String albumId;
  final String? assetId;

  @override
  State<ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<ActivitySheet> {
  final _text = TextEditingController();
  Activity? _activity;
  bool _failedLoad = false;
  Timer? _poll;

  DefaultApi get _api => widget.session.api;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final next = await _api.listAlbumComments(
        widget.albumId,
        assetId: widget.assetId,
      );
      if (mounted) {
        setState(() {
          _activity = next;
          _failedLoad = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failedLoad = true);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } on ApiException catch (cause) {
      if (mounted) _failed(context, cause);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    final text = Theme.of(context).textTheme;
    return SheetFrame(
      title: widget.assetId == null ? 'Comments' : 'Comments and hearts',
      children: [
        if (activity == null)
          _failedLoad
              ? const Text('Comments could not be loaded.')
              : const Center(
                  child: CircularProgressIndicator(color: Palette.gold),
                )
        else ...[
          if (widget.assetId != null)
            Row(
              children: [
                IconButton(
                  tooltip: 'Heart',
                  icon: Icon(
                    activity.hearted ? Icons.favorite : Icons.favorite_border,
                    color: activity.hearted ? Palette.gold : null,
                  ),
                  onPressed: () => _run(
                    () => activity.hearted
                        ? _api.removeAlbumHeart(widget.albumId, widget.assetId!)
                        : _api.setAlbumHeart(widget.albumId, widget.assetId!),
                  ),
                ),
                Text('${activity.hearts}', style: text.bodyLarge),
              ],
            ),
          if (activity.comments.isEmpty)
            Text(
              'No comments yet.',
              style: text.bodyMedium?.copyWith(color: Palette.dim),
            ),
          for (final comment in activity.comments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(comment.userName),
              subtitle: Text(comment.body),
              trailing: comment.canDelete
                  ? IconButton(
                      tooltip: 'Delete comment',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _run(
                        () =>
                            _api.deleteAlbumComment(widget.albumId, comment.id),
                      ),
                    )
                  : null,
            ),
          TextField(
            controller: _text,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Comment'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _run(() async {
                final body = _text.text.trim();
                if (body.isEmpty) return;
                await _api.createAlbumComment(
                  widget.albumId,
                  CommentCreate(body: body, assetId: widget.assetId),
                );
                _text.clear();
              }),
              child: const Text('Send'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Adds photos to one of the albums this user can add to, or to a new one.
Future<bool> showAddToAlbum(
  BuildContext context,
  Session session,
  List<String> ids,
) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddToAlbumSheet(session: session, ids: ids),
  );
  return added == true;
}

class _AddToAlbumSheet extends StatefulWidget {
  const _AddToAlbumSheet({required this.session, required this.ids});

  final Session session;
  final List<String> ids;

  @override
  State<_AddToAlbumSheet> createState() => _AddToAlbumSheetState();
}

class _AddToAlbumSheetState extends State<_AddToAlbumSheet> {
  final _title = TextEditingController();
  List<Album>? _albums;
  bool _failedLoad = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await widget.session.api.listAlbums(sort: 'title');
      if (!mounted) return;
      setState(() {
        _albums = (all ?? const <Album>[])
            .where(
              (album) => AlbumRights(album.role, isSmart: album.isSmart).canAdd,
            )
            .toList();
      });
    } on ApiException {
      if (mounted) setState(() => _failedLoad = true);
    }
  }

  Future<void> _add(String id) async {
    final navigator = Navigator.of(context);
    try {
      await widget.session.api.addAlbumAssets(id, AssetIds(ids: widget.ids));
      navigator.pop(true);
    } on ApiException catch (cause) {
      if (mounted) _failed(context, cause);
    }
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    try {
      final album = await widget.session.api.createAlbum(
        AlbumCreate(title: title),
      );
      if (album != null) await _add(album.id);
    } on ApiException catch (cause) {
      if (mounted) _failed(context, cause);
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: 'Add to album',
    children: [
      if (_failedLoad) const Text('Albums could not be loaded.'),
      if (_albums == null && !_failedLoad)
        const Center(child: CircularProgressIndicator(color: Palette.gold)),
      for (final album in _albums ?? const <Album>[])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.photo_album_outlined),
          title: Text(album.title),
          trailing: Text('${album.assetCount}'),
          onTap: () => _add(album.id),
        ),
      TextField(
        controller: _title,
        maxLength: 200,
        decoration: const InputDecoration(labelText: 'New album'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _create,
          child: const Text('Create and add'),
        ),
      ),
    ],
  );
}

/// Who an album is shared with, and in what role. Only its owner opens this.
class ShareSheet extends StatefulWidget {
  const ShareSheet({
    super.key,
    required this.session,
    required this.albumId,
    required this.onChanged,
  });

  final Session session;
  final String albumId;
  final VoidCallback onChanged;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  List<AlbumMember>? _members;
  List<UserRef> _users = const [];
  bool _failedLoad = false;
  String? _userId;
  MemberRoleRoleEnum _role = MemberRoleRoleEnum.viewer;

  DefaultApi get _api => widget.session.api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final album = await _api.getAlbum(widget.albumId);
      final users = await _api.listDirectory();
      if (!mounted) return;
      setState(() {
        _members = album?.members ?? const [];
        _users = users ?? const [];
      });
    } on ApiException {
      if (mounted) setState(() => _failedLoad = true);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
      widget.onChanged();
    } on ApiException catch (cause) {
      if (mounted) _failed(context, cause);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _members;
    final free = _users
        .where((user) => !(members ?? const []).any((m) => m.userId == user.id))
        .toList();
    return SheetFrame(
      title: 'Share with users',
      children: [
        if (_failedLoad) const Text('Sharing could not be loaded.'),
        if (members == null && !_failedLoad)
          const Center(child: CircularProgressIndicator(color: Palette.gold)),
        if (members != null && members.isEmpty)
          const Text('This album is not shared yet.'),
        for (final member in members ?? const <AlbumMember>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(member.name),
            subtitle: DropdownButton<MemberRoleRoleEnum>(
              value: MemberRoleRoleEnum.fromJson(member.role.toString()),
              underline: const SizedBox.shrink(),
              items: [
                for (final role in MemberRoleRoleEnum.values)
                  DropdownMenuItem(value: role, child: Text(roleLabel(role))),
              ],
              onChanged: (role) {
                if (role == null) return;
                _run(
                  () => _api.setAlbumMember(
                    widget.albumId,
                    member.userId,
                    MemberRole(role: role),
                  ),
                );
              },
            ),
            trailing: TextButton(
              onPressed: () => _run(
                () => _api.removeAlbumMember(widget.albumId, member.userId),
              ),
              child: const Text('Remove'),
            ),
          ),
        const SizedBox(height: 16),
        if (members != null && _users.isEmpty)
          const Text('There are no other users on this server.'),
        if (free.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _userId,
            decoration: const InputDecoration(labelText: 'User'),
            items: [
              for (final user in free)
                DropdownMenuItem(value: user.id, child: Text(user.name)),
            ],
            onChanged: (value) => setState(() => _userId = value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MemberRoleRoleEnum>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              for (final role in MemberRoleRoleEnum.values)
                DropdownMenuItem(value: role, child: Text(roleLabel(role))),
            ],
            onChanged: (value) => setState(() => _role = value ?? _role),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _userId == null
                  ? null
                  : () => _run(() async {
                      await _api.setAlbumMember(
                        widget.albumId,
                        _userId!,
                        MemberRole(role: _role),
                      );
                      _userId = null;
                    }),
              child: const Text('Add'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Public links of an album. Only its owner opens this.
class LinksSheet extends StatefulWidget {
  const LinksSheet({
    super.key,
    required this.session,
    required this.albumId,
    required this.isSmart,
  });

  final Session session;
  final String albumId;
  final bool isSmart;

  @override
  State<LinksSheet> createState() => _LinksSheetState();
}

class _LinksSheetState extends State<LinksSheet> {
  final _label = TextEditingController();
  final _password = TextEditingController();
  final _limit = TextEditingController();
  final _watermark = TextEditingController();
  List<ShareLink>? _links;
  bool _failedLoad = false;
  String? _created;
  DateTime? _expires;
  bool _allowDownload = true;
  bool _allowUpload = false;
  bool _uploadOnly = false;
  bool _showLocation = false;

  DefaultApi get _api => widget.session.api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _label.dispose();
    _password.dispose();
    _limit.dispose();
    _watermark.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final links = await _api.listAlbumLinks(widget.albumId);
      if (mounted) setState(() => _links = links ?? const []);
    } on ApiException {
      if (mounted) setState(() => _failedLoad = true);
    }
  }

  Future<void> _create() async {
    try {
      final link = await _api.createAlbumLink(
        widget.albumId,
        ShareLinkCreate(
          label: _label.text.trim(),
          password: _password.text.isEmpty ? null : _password.text,
          expiresAt: _expires,
          downloadLimit: int.tryParse(_limit.text),
          watermark: _watermark.text.trim().isEmpty
              ? null
              : _watermark.text.trim(),
          allowDownload: _allowDownload,
          allowUpload: _allowUpload,
          uploadOnly: _uploadOnly,
          showLocation: _showLocation,
        ),
      );
      if (link?.token != null) {
        setState(() {
          _created = publicLinkUrl(widget.session.serverUrl, link!.token!);
          _label.clear();
          _password.clear();
          _limit.clear();
          _watermark.clear();
          _expires = null;
        });
      }
      await _load();
    } on ApiException catch (cause) {
      if (mounted) _failed(context, cause);
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _expires = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    final dim = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Palette.dim);
    return SheetFrame(
      title: 'Public links',
      children: [
        if (created != null) ...[
          const Text('Copy the address now: it cannot be shown again later.'),
          SelectableText(created),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: created)),
              child: const Text('Copy'),
            ),
          ),
        ],
        if (_failedLoad) const Text('Links could not be loaded.'),
        if (_links == null && !_failedLoad)
          const Center(child: CircularProgressIndicator(color: Palette.gold)),
        for (final link in _links ?? const <ShareLink>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(link.label.isEmpty ? 'Unnamed link' : link.label),
            subtitle: Text(linkSummary(link)),
            trailing: TextButton(
              onPressed: () async {
                try {
                  await _api.deleteAlbumLink(widget.albumId, link.id);
                  await _load();
                } on ApiException catch (cause) {
                  if (context.mounted) _failed(context, cause);
                }
              },
              child: const Text('Revoke', style: TextStyle(color: Palette.err)),
            ),
          ),
        const Divider(color: Palette.line),
        TextField(
          controller: _label,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password (optional)'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _expires == null ? 'No expiry' : 'Expires ${_day(_expires!)}',
          ),
          trailing: TextButton(
            onPressed: _pickExpiry,
            child: const Text('Choose'),
          ),
        ),
        if (!_uploadOnly) ...[
          TextField(
            controller: _limit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Download limit'),
          ),
          TextField(
            controller: _watermark,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Watermark'),
          ),
          Text(
            'A watermark turns off original downloads and video playback.',
            style: dim,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow downloads'),
            value: _allowDownload,
            onChanged: (value) => setState(() => _allowDownload = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show location'),
            value: _showLocation,
            onChanged: (value) => setState(() => _showLocation = value),
          ),
        ],
        if (!widget.isSmart) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Guests can add photos'),
            value: _allowUpload,
            onChanged: (value) => setState(() => _allowUpload = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Upload only (guests do not see the album)'),
            value: _uploadOnly,
            onChanged: (value) => setState(() => _uploadOnly = value),
          ),
        ],
        const SizedBox(height: 8),
        GoldButton(label: 'Create link', onPressed: _create),
      ],
    );
  }
}

/// The conditions of a smart album.
class RulesEditor extends StatefulWidget {
  const RulesEditor({
    super.key,
    required this.session,
    required this.rules,
    required this.onChanged,
  });

  final Session session;
  final AlbumRules rules;
  final ValueChanged<AlbumRules> onChanged;

  @override
  State<RulesEditor> createState() => _RulesEditorState();
}

class _RulesEditorState extends State<RulesEditor> {
  List<String> _cameras = const [];
  late DateTime? _from = widget.rules.from;
  late DateTime? _to = widget.rules.to;
  late AlbumRulesKindEnum? _kind = widget.rules.kind;
  late String? _camera = widget.rules.camera;
  late String? _person = widget.rules.person;
  late String? _tag = widget.rules.tag;
  late final _place = TextEditingController(text: widget.rules.place);
  List<Person> _people = const [];
  List<Tag> _tags = const [];

  @override
  void initState() {
    super.initState();
    widget.session.api.listCameras().then((value) {
      if (mounted) setState(() => _cameras = value ?? const []);
    }, onError: (Object _) {});
    widget.session.api.listPeople().then((value) {
      if (mounted) {
        setState(() {
          _people = (value?.people ?? const <Person>[])
              .where((person) => person.name.isNotEmpty)
              .toList();
        });
      }
    }, onError: (Object _) {});
    widget.session.api.listTags().then((value) {
      if (mounted) setState(() => _tags = value ?? const []);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  void _notify() {
    setState(() {});
    widget.onChanged(
      AlbumRules(
        from: _from,
        to: _to,
        kind: _kind,
        camera: _camera,
        person: _person,
        tag: _tag,
        place: _place.text.trim().isEmpty ? null : _place.text.trim(),
      ),
    );
  }

  Future<DateTime?> _date(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime(2100),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_from == null ? 'From any date' : 'From ${_day(_from!)}'),
        trailing: TextButton(
          child: const Text('Choose'),
          onPressed: () async {
            final picked = await _date(_from);
            if (picked != null) {
              _from = picked;
              _notify();
            }
          },
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_to == null ? 'To any date' : 'To ${_day(_to!)}'),
        trailing: TextButton(
          child: const Text('Choose'),
          onPressed: () async {
            final picked = await _date(_to);
            if (picked != null) {
              _to = picked;
              _notify();
            }
          },
        ),
      ),
      DropdownButtonFormField<AlbumRulesKindEnum?>(
        initialValue: _kind,
        decoration: const InputDecoration(labelText: 'Kind'),
        items: const [
          DropdownMenuItem(child: Text('All')),
          DropdownMenuItem(
            value: AlbumRulesKindEnum.photo,
            child: Text('Photos'),
          ),
          DropdownMenuItem(
            value: AlbumRulesKindEnum.video,
            child: Text('Videos'),
          ),
          DropdownMenuItem(
            value: AlbumRulesKindEnum.live,
            child: Text('Live Photo'),
          ),
        ],
        onChanged: (value) {
          _kind = value;
          _notify();
        },
      ),
      DropdownButtonFormField<String?>(
        key: ValueKey(_cameras.length),
        initialValue: _cameras.contains(_camera) ? _camera : null,
        decoration: const InputDecoration(labelText: 'Camera'),
        items: [
          const DropdownMenuItem(child: Text('All')),
          for (final camera in _cameras)
            DropdownMenuItem(value: camera, child: Text(camera)),
        ],
        onChanged: (value) {
          _camera = value;
          _notify();
        },
      ),
      DropdownButtonFormField<String?>(
        key: ValueKey('people${_people.length}'),
        initialValue: _people.any((person) => person.id == _person)
            ? _person
            : null,
        decoration: const InputDecoration(labelText: 'Person'),
        items: [
          const DropdownMenuItem(child: Text('All')),
          for (final person in _people)
            DropdownMenuItem(value: person.id, child: Text(person.name)),
        ],
        onChanged: (value) {
          _person = value;
          _notify();
        },
      ),
      DropdownButtonFormField<String?>(
        key: ValueKey('tags${_tags.length}'),
        initialValue: _tags.any((tag) => tag.id == _tag) ? _tag : null,
        decoration: const InputDecoration(labelText: 'Tag'),
        items: [
          const DropdownMenuItem(child: Text('All')),
          for (final tag in _tags)
            DropdownMenuItem(value: tag.id, child: Text(tag.name)),
        ],
        onChanged: (value) {
          _tag = value;
          _notify();
        },
      ),
      TextField(
        controller: _place,
        decoration: const InputDecoration(labelText: 'Place'),
        onChanged: (_) => _notify(),
      ),
    ],
  );
}
