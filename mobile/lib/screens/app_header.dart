import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/session.dart';
import '../services/settings.dart';
import '../services/uploads.dart';
import '../theme.dart';
import 'account_sheet.dart';
import 'upload_screen.dart';

/// The top of every main screen: the name, backup, adding something, and the account.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key, this.onAdd});

  /// What "+" does here. Without it, "+" uploads from this phone.
  final VoidCallback? onAdd;

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
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 4),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset('assets/logo.png', width: 30, height: 30),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'mediarr.',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: Palette.gold,
              ),
            ),
          ),
          if (!readOnly) ...[
            IconButton(
              tooltip: 'Backup',
              icon: Badge(
                isLabelVisible: working > 0,
                label: Text('$working'),
                child: Icon(Icons.sync, color: Palette.gold),
              ),
              onPressed: openUpload,
            ),
            IconButton(
              tooltip: 'Add',
              icon: Icon(Icons.add, color: Palette.gold),
              onPressed: onAdd ?? openUpload,
            ),
          ],
          IconButton(
            tooltip: 'Account',
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: Palette.bg3,
              child: Text(
                name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Palette.ink),
              ),
            ),
            onPressed: () => showAccountSheet(context),
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
