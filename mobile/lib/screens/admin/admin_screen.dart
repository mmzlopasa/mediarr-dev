import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';
import '../backup_screen.dart';
import '../devices_screen.dart';
import '../exports_screen.dart';
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
        l.adminScreenOverview,
        l.adminScreenOverviewHint,
        const AdminOverviewScreen(),
      ),
      (
        Icons.group_outlined,
        l.adminScreenUsers,
        l.adminScreenUsersHint,
        const AdminUsersScreen(),
      ),
      (
        Icons.tune,
        l.adminScreenServerSettings,
        l.adminScreenServerSettingsHint,
        const ServerSettingsScreen(),
      ),
      (
        Icons.mail_outline,
        l.adminScreenEmail,
        l.adminScreenEmailHint,
        const EmailSettingsScreen(),
      ),
      (
        Icons.shield_outlined,
        l.adminScreenSecurity,
        l.adminScreenSecurityHint,
        const SecurityScreen(),
      ),
      (
        Icons.work_history_outlined,
        l.adminScreenJobs,
        l.adminScreenJobsHint,
        const JobsScreen(),
      ),
      (
        Icons.history,
        l.adminScreenAuditLog,
        l.adminScreenAuditLogHint,
        const AuditScreen(),
      ),
      (
        Icons.backup_outlined,
        l.settingsScreenBackup,
        l.adminScreenBackupHint,
        const BackupScreen(),
      ),
      (
        Icons.devices_other_outlined,
        l.adminScreenBackupDevices,
        l.adminScreenBackupDevicesHint,
        const BackupDevicesScreen(all: true),
      ),
      (
        Icons.drive_file_move_outline,
        l.adminScreenStorageTemplate,
        l.adminScreenStorageTemplateHint,
        const StorageTemplateScreen(),
      ),
      (
        Icons.ios_share,
        l.adminScreenExports,
        l.adminScreenExportsHint,
        const ExportsScreen(all: true),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.adminScreenTitle)),
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
