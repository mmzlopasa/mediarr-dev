import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup.dart';
import '../services/session.dart';
import '../theme.dart';
import 'organize_screens.dart';
import 'settings_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final text = Theme.of(context).textTheme;
    if (session == null) return const SizedBox.shrink();

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: Palette.dim)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.bodyLarge,
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Account', style: text.headlineMedium),
          const SizedBox(height: 20),
          row('Name', session.user.name),
          Divider(color: Palette.line),
          row('Email', session.user.email),
          Divider(color: Palette.line),
          row('Server', session.serverUrl),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const OrganizeLinks(),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.ink,
              side: BorderSide(color: Palette.line2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              // Otherwise the device would keep uploading after signing out.
              final backup = ref.read(backupProvider);
              final notifier = ref.read(sessionProvider.notifier);
              try {
                await backup.disable(session);
              } on MissingPluginException {
                // No native engine on this platform.
              }
              await forgetVaultPin();
              await notifier.signOut();
            },
          ),
        ],
      ),
    );
  }
}
