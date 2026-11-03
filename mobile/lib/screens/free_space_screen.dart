import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/backup.dart';
import '../services/session.dart';
import '../theme.dart';

const _checkBatch = 1000;

/// Removes from the phone only what the server confirms having at this moment.
class FreeSpaceScreen extends ConsumerStatefulWidget {
  const FreeSpaceScreen({super.key});

  @override
  ConsumerState<FreeSpaceScreen> createState() => _FreeSpaceScreenState();
}

class _FreeSpaceScreenState extends ConsumerState<FreeSpaceScreen> {
  List<AssetEntity>? _assets;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fails closed: if the server cannot be asked, nothing is offered.
  Future<void> _load() async {
    setState(() {
      _assets = null;
      _error = null;
    });
    try {
      final session = ref.read(sessionProvider).value!;
      final verified = await ref.read(backupProvider).verifiedChecksums();
      final checksums = {for (final list in verified.values) ...list}.toList();
      final onServer = <String>{};
      for (var start = 0; start < checksums.length; start += _checkBatch) {
        final answer = await session.api.checkAssets(
          ChecksumCheckRequest(
            checksums: checksums.sublist(
              start,
              (start + _checkBatch).clamp(0, checksums.length),
            ),
          ),
        );
        onServer.addAll(answer?.existing ?? const []);
      }
      final assets = <AssetEntity>[];
      for (final id in safeToRemove(verified, onServer)) {
        final asset = await AssetEntity.fromId(id);
        if (asset != null) assets.add(asset);
      }
      if (mounted) setState(() => _assets = assets);
    } on ApiException {
      if (mounted) {
        setState(
          () => _error = 'The server could not be asked, so nothing is offered for removal.',
        );
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _error = 'The backup state could not be read.');
      }
    }
  }

  Future<void> _remove(List<AssetEntity> assets) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${assets.length} from this phone?'),
        content: const Text(
          'They stay on your server. iPhone asks once more, and keeps them for 30 days in Recently Deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Palette.err)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await PhotoManager.editor.deleteWithIds([
        for (final asset in assets) asset.id,
      ]);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The photos could not be removed.')),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final assets = _assets;
    final Widget body;
    if (_error != null) {
      body = EmptyMessage(icon: Icons.cloud_off, text: _error!);
    } else if (assets == null) {
      body = const Center(
        child: CircularProgressIndicator(color: Palette.gold),
      );
    } else if (assets.isEmpty) {
      body = const EmptyMessage(
        icon: Icons.cleaning_services_outlined,
        text: 'Nothing to remove. Only photos sent by the automatic backup are offered here.',
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              '${assets.length} are safely on your server, as it just confirmed by their checksums.',
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: assets.length,
              itemBuilder: (_, index) => _Thumbnail(asset: assets[index]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GoldButton(
                label: 'Remove ${assets.length} from this phone',
                busy: _busy,
                onPressed: () => _remove(assets),
              ),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Free up space')),
      body: body,
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
    builder: (_, snapshot) => snapshot.data == null
        ? const ColoredBox(color: Palette.bg3)
        : Image.memory(snapshot.data!, fit: BoxFit.cover),
  );
}
