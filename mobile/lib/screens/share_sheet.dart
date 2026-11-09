import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../services/sharing.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

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
        title: Text(l.shareSheetVaultTitle),
        content: Text(l.shareSheetVaultBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.shareSheetCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.shareSheetContinue),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
  }
  final settings = ref.read(settingsProvider);
  var privacy = SharePrivacy(
    removeLocation: settings.shareRemoveLocation,
    removeCamera: settings.shareRemoveCamera,
    hideFaces: settings.shareHideFaces,
  );
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  ids.length == 1
                      ? l.shareSheetSendThis
                      : l.shareSheetSendCount('${ids.length}'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final option in [false, true])
                ListTile(
                  leading: Icon(
                    option ? Icons.compress : Icons.photo_outlined,
                    color: Palette.dim,
                  ),
                  title: Text(
                    option ? l.shareSheetSmaller : l.shareSheetOriginal,
                  ),
                  subtitle: Text(
                    option
                        ? l.shareSheetSmallerDetail
                        : l.shareSheetOriginalDetail,
                  ),
                  trailing: settings.shareSmall == option
                      ? Icon(Icons.check, color: Palette.gold)
                      : null,
                  onTap: () =>
                      Navigator.pop(context, option ? 'small' : 'original'),
                ),
              Divider(height: 1, color: Palette.line),
              SwitchListTile(
                key: const ValueKey('share-remove-location'),
                title: Text(l.sharePrivacyRemoveLocation),
                value: privacy.removeLocation,
                onChanged: (value) => setSheet(
                  () => privacy = SharePrivacy(
                    removeLocation: value,
                    removeCamera: privacy.removeCamera,
                    hideFaces: privacy.hideFaces,
                  ),
                ),
              ),
              SwitchListTile(
                key: const ValueKey('share-remove-camera'),
                title: Text(l.sharePrivacyRemoveCamera),
                value: privacy.removeCamera,
                onChanged: (value) => setSheet(
                  () => privacy = SharePrivacy(
                    removeLocation: privacy.removeLocation,
                    removeCamera: value,
                    hideFaces: privacy.hideFaces,
                  ),
                ),
              ),
              SwitchListTile(
                key: const ValueKey('share-hide-faces'),
                title: Text(l.sharePrivacyHideFaces),
                subtitle: Text(l.sharePrivacyHideFacesDetail),
                value: privacy.hideFaces,
                onChanged: (value) => setSheet(
                  () => privacy = SharePrivacy(
                    removeLocation: privacy.removeLocation,
                    removeCamera: privacy.removeCamera,
                    hideFaces: value,
                  ),
                ),
              ),
              Divider(height: 1, color: Palette.line),
              ListTile(
                leading: Icon(Icons.download_outlined, color: Palette.dim),
                title: Text(l.shareSheetSaveToPhone),
                subtitle: Text(l.shareSheetSaveDetail),
                onTap: () => Navigator.pop(context, 'save'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'save') {
    await saveAssetsToPhone(context, session, ids);
    return;
  }
  final small = choice == 'small';
  if (small != settings.shareSmall ||
      privacy.removeLocation != settings.shareRemoveLocation ||
      privacy.removeCamera != settings.shareRemoveCamera ||
      privacy.hideFaces != settings.shareHideFaces) {
    await ref
        .read(settingsProvider.notifier)
        .change(
          settings.copyWith(
            shareSmall: small,
            shareRemoveLocation: privacy.removeLocation,
            shareRemoveCamera: privacy.removeCamera,
            shareHideFaces: privacy.hideFaces,
          ),
        );
  }
  if (!context.mounted) return;
  final size = MediaQuery.sizeOf(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final files = await _fetch(
    context,
    session,
    ids,
    small: small,
    privacy: privacy,
  );
  if (files == null || files.isEmpty) {
    if (files != null && privacy.hideFaces) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.sharePrivacyVideosLeftOut)),
      );
    }
    return;
  }
  if (files.length < ids.length && privacy.hideFaces) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l.sharePrivacyVideosLeftOut)),
    );
  }
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
              ? l.shareSheetSavedOne
              : l.shareSheetSavedMany('${files.length}'),
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
  SharePrivacy privacy = SharePrivacy.none,
}) async {
  final progress = ValueNotifier<int>(0);
  var cancelled = false;
  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l.shareSheetGettingReady),
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
            Text(l.shareSheetProgress('$done', '${ids.length}')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            cancelled = true;
            Navigator.pop(context);
          },
          child: Text(l.shareSheetCancel),
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
      privacy: privacy,
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
      messenger?.showSnackBar(SnackBar(content: Text(l.shareSheetFetchFailed)));
    }
    return null;
  } finally {
    progress.dispose();
  }
}
