import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../services/uploads.dart';
import '../theme.dart';
import 'account_sheet.dart';
import 'notifications.dart';
import 'upload_screen.dart';

/// The top of every main screen: its title, the gold action and the account, as on the web.
class AppHeader extends ConsumerWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.actionLabel = 'Upload',
    this.onAction,
  });

  final String title;
  final String actionLabel;

  /// What the gold button does here. Without it, it opens backup and upload.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final readOnly = ref.watch(settingsProvider).readOnly;
    final working = ref
        .watch(uploadsProvider)
        .where((task) => !task.finished)
        .length;
    void openUpload() =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const UploadPage()));
    final name = session?.user.name.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          if (!readOnly)
            Tooltip(
              message: 'Add',
              child: Semantics(
                button: true,
                label: actionLabel,
                child: GestureDetector(
                  onTap: onAction ?? openUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18, color: Palette.onGold),
                        const SizedBox(width: 4),
                        Text(
                          working > 0 ? '$actionLabel · $working' : actionLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter Tight',
                            color: Palette.onGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const NotificationBell(),
          Tooltip(
            message: 'Account',
            child: GestureDetector(
              onTap: () => showAccountSheet(context),
              child: Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.bg3,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.bg2,
                  ),
                  child: Text(
                    name.isEmpty
                        ? '?'
                        : name
                              .substring(0, name.length < 2 ? 1 : 2)
                              .toUpperCase(),
                    style: TextStyle(
                      color: Palette.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup and upload')),
    body: const UploadScreen(),
  );
}
