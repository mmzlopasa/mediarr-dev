import '../motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../theme.dart';
import 'profile_screen.dart';
import 'account_sheet.dart';
import 'notifications.dart';
import 'upload_screen.dart';

/// The top of every main screen: its title, its own gold action when it has one, notifications
/// and the account, as on the web. Uploading lives in the dock's +.
class AppHeader extends ConsumerWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.actionLabel = 'New',
    this.onAction,
  });

  final String title;
  final String actionLabel;

  /// What the gold button does here; without it there is no button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final readOnly = ref.watch(settingsProvider).readOnly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TitleRise(
              key: ValueKey(title),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          if (!readOnly && onAction != null)
            Tooltip(
              message: 'Add',
              child: Semantics(
                button: true,
                label: actionLabel,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.buttonGold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18, color: Palette.onGold),
                        const SizedBox(width: 4),
                        Text(
                          actionLabel,
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
                  color: Palette.bg2,
                ),
                child: session == null
                    ? const SizedBox()
                    : PersonAvatar(
                        session: session,
                        user: session.user,
                        size: 39,
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
