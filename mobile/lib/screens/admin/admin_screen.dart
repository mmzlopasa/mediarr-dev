import 'package:flutter/material.dart';

import '../../theme.dart';
import '../backup_screen.dart';
import '../devices_screen.dart';
import '../storage_template_screen.dart';
import 'audit_screen.dart';
import 'email_screen.dart';
import 'jobs_screen.dart';
import 'overview_screen.dart';
import 'security_screen.dart';
import 'server_settings_screen.dart';
import 'users_screen.dart';

/// Everything an administrator can do on the web, in the app.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <(IconData, String, String, Widget)>[
      (
        Icons.insights_outlined,
        'Overview',
        'Users, photos, disk and versions',
        const AdminOverviewScreen(),
      ),
      (
        Icons.group_outlined,
        'Users',
        'Add users and set how much they may store',
        const AdminUsersScreen(),
      ),
      (
        Icons.tune,
        'Server settings',
        'Trash, quality, faces, jobs, sign-in',
        const ServerSettingsScreen(),
      ),
      (
        Icons.mail_outline,
        'Email',
        'Where messages are sent from',
        const EmailSettingsScreen(),
      ),
      (
        Icons.shield_outlined,
        'Security',
        'Single sign-on, devices, addresses, attempts',
        const SecurityScreen(),
      ),
      (
        Icons.work_history_outlined,
        'Jobs',
        'Queues and jobs that failed',
        const JobsScreen(),
      ),
      (Icons.history, 'Audit log', 'Who changed what', const AuditScreen()),
      (
        Icons.backup_outlined,
        'Backup',
        'Copies of the library',
        const BackupScreen(),
      ),
      (
        Icons.devices_other_outlined,
        'All backup devices',
        'Every phone that backs up',
        const BackupDevicesScreen(all: true),
      ),
      (
        Icons.drive_file_move_outline,
        'Storage template',
        'How originals are laid out on the disk',
        const StorageTemplateScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        children: [
          for (final (icon, title, subtitle, screen) in sections)
            ListTile(
              leading: Icon(icon, color: Palette.dim),
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => screen)),
            ),
        ],
      ),
    );
  }
}
