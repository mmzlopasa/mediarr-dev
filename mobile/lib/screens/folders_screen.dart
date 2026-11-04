import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'asset_picture.dart';
import 'viewer_screen.dart';

/// The folder one level inside another, or at the top of the library.
String folderChild(String path, String name) =>
    path.isEmpty ? name : '$path/$name';

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key, this.path = ''});

  final String path;

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  Folder? _folder;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final folder = await _session.api.getFolder(path: widget.path);
      if (mounted) {
        setState(() {
          _folder = folder;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Widget _picture(String id) => AssetPicture(
    session: _session,
    id: id,
    fit: BoxFit.cover,
    memCacheWidth: 300,
    error: const Icon(Icons.broken_image_outlined),
  );

  Widget _grid(Folder folder) {
    final store = TimelineStore.fixed(_session, folder.items);
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.all(4),
      children: [
        for (final child in folder.folders)
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    FoldersScreen(path: folderChild(widget.path, child.name)),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _picture(child.coverId),
                const ColoredBox(color: Colors.black38),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.folder, color: Colors.white, size: 18),
                      Text(
                        child.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${child.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        for (final (index, item) in folder.items.indexed)
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (_) => ViewerScreen(
                      initialIndex: index,
                      store: store,
                      session: _session,
                    ),
                  ),
                )
                .then((_) => _load()),
            child: _picture(item.id),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final folder = _folder;
    final title = widget.path.isEmpty ? 'Folders' : widget.path.split('/').last;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: folder == null
          ? _failed
                ? const EmptyMessage(
                    icon: Icons.cloud_off,
                    text: 'The folder could not be loaded.',
                  )
                : Center(child: CircularProgressIndicator(color: Palette.gold))
          : !folder.available
          ? const EmptyMessage(
              icon: Icons.folder_outlined,
              text: 'You have no external library. An administrator sets it up in Settings.',
            )
          : folder.folders.isEmpty && folder.items.isEmpty
          ? const EmptyMessage(
              icon: Icons.folder_outlined,
              text: 'This folder is empty.',
            )
          : _grid(folder),
    );
  }
}
