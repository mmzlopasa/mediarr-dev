import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../services/sharing.dart';
import '../theme.dart';

/// Sends photos and videos to another app, or saves them on the phone. The person picks the original
/// or a smaller file for messages, and the choice is kept for next time.
Future<void> shareAssets(
  BuildContext context,
  WidgetRef ref,
  Session session,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  // A photo from the vault leaves a protected place, so that is asked first.
  if (session is CollectionSession && session.scope == 'vault') {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take it out of the vault?'),
        content: const Text(
          'Once sent or saved, it is no longer protected by your PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
  }
  final settings = ref.read(settingsProvider);
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              ids.length == 1 ? 'Send this' : 'Send ${ids.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final option in [false, true])
            ListTile(
              leading: Icon(
                option ? Icons.compress : Icons.photo_outlined,
                color: Palette.dim,
              ),
              title: Text(option ? 'Smaller, for messages' : 'Original'),
              subtitle: Text(
                option
                    ? 'A JPEG of at most 2048 px, without location'
                    : 'As it is, with everything in it',
              ),
              trailing: settings.shareSmall == option
                  ? Icon(Icons.check, color: Palette.gold)
                  : null,
              onTap: () =>
                  Navigator.pop(context, option ? 'small' : 'original'),
            ),
          Divider(height: 1, color: Palette.line),
          ListTile(
            leading: Icon(Icons.download_outlined, color: Palette.dim),
            title: const Text('Save to this phone'),
            subtitle: const Text('The original, in the phone’s gallery'),
            onTap: () => Navigator.pop(context, 'save'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'save') {
    await saveAssetsToPhone(context, session, ids);
    return;
  }
  final small = choice == 'small';
  if (small != settings.shareSmall) {
    await ref
        .read(settingsProvider.notifier)
        .change(settings.copyWith(shareSmall: small));
  }
  if (!context.mounted) return;
  final size = MediaQuery.sizeOf(context);
  final files = await _fetch(context, session, ids, small: small);
  if (files == null || files.isEmpty) return;
  // An iPad shows the sheet as a popover, which needs a place on the screen.
  await shareFiles(
    files,
    origin: Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1),
  );
}

/// Saves the originals in the phone's own gallery.
Future<void> saveAssetsToPhone(
  BuildContext context,
  Session session,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final files = await _fetch(context, session, ids, small: false);
  if (files == null || files.isEmpty) return;
  try {
    await saveToPhone(files);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          files.length == 1
              ? 'Saved to this phone.'
              : '${files.length} saved to this phone.',
        ),
      ),
    );
  } on FileSystemException catch (cause) {
    messenger?.showSnackBar(SnackBar(content: Text(cause.message)));
  }
}

/// Downloads with a progress dialog that can be cancelled. Null when it was cancelled or failed.
Future<List<File>?> _fetch(
  BuildContext context,
  Session session,
  List<String> ids, {
  required bool small,
}) async {
  final progress = ValueNotifier<int>(0);
  var cancelled = false;
  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Getting it ready'),
      content: ValueListenableBuilder<int>(
        valueListenable: progress,
        builder: (_, done, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: ids.length > 1 ? done / ids.length : null,
              color: Palette.gold,
              backgroundColor: Palette.bg3,
            ),
            const SizedBox(height: 10),
            Text('$done of ${ids.length}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            cancelled = true;
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final files = await fetchForSharing(
      session,
      ids,
      small: small,
      onProgress: (done, _) => progress.value = done,
      cancelled: () => cancelled,
    );
    if (cancelled) return null;
    navigator.pop();
    await dialog;
    return files;
  } on Object catch (_) {
    if (!cancelled) {
      navigator.pop();
      messenger?.showSnackBar(
        const SnackBar(content: Text('The files could not be fetched.')),
      );
    }
    return null;
  } finally {
    progress.dispose();
  }
}
