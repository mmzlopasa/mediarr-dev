import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'asset_picture.dart';
import 'viewer_screen.dart';

/// Why the album is empty, in the order that matters to the person looking at it.
String documentsEmptyText(Documents data) {
  if (!data.enabled) return 'An administrator has not turned this album on.';
  if (!data.analysisOn) return 'This needs picture analysis to be on.';
  return 'No photos with text yet.';
}

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  Documents? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _session.api.getDocuments();
      if (mounted) {
        setState(() {
          _data = data;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final Widget body;
    if (data == null) {
      body = _failed
          ? const EmptyMessage(
              icon: Icons.cloud_off,
              text: 'Documents could not be loaded.',
            )
          : const Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (data.items.isEmpty) {
      body = EmptyMessage(
        icon: Icons.description_outlined,
        text: documentsEmptyText(data),
      );
    } else {
      final store = TimelineStore.fixed(_session, data.items);
      body = GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        padding: const EdgeInsets.all(4),
        children: [
          for (final (index, item) in data.items.indexed)
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
              child: AssetPicture(
                session: _session,
                id: item.id,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                error: const Icon(Icons.broken_image_outlined),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: body,
    );
  }
}
